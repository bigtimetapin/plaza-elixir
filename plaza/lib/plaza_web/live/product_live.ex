defmodule PlazaWeb.ProductLive do
  use PlazaWeb, :live_view

  require Logger

  alias Ecto.Changeset

  alias Plaza.Accounts
  alias Plaza.Accounts.Address
  alias Plaza.Accounts.Seller
  alias Plaza.Dimona
  alias Plaza.Products
  alias Plaza.Products.Product
  alias Plaza.Purchases
  alias PlazaWeb.ProductComponent

  @local_storage_key "plaza-checkout-cart"

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket =
      if connected?(socket) do
        socket
        |> assign(cart: [])
        |> assign(cart_product_size: "m")
        |> assign(already_in_cart: false)
        |> push_event(
          "read",
          %{
            key: @local_storage_key,
            event: "read-cart"
          }
        )
      else
        socket
        |> assign(waiting: true)
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"product-id" => product_id} = params, _uri, socket) do
    socket =
      if connected?(socket) do
        {product, seller} =
          case Products.get_product(product_id) do
            nil ->
              {nil, nil}

            product ->
              case Accounts.get_seller_by_id(product.user_id) do
                nil ->
                  {nil, nil}

                seller ->
                  {product, seller}
              end
          end

        socket =
          case {product, seller} do
            {%{active: false}, _} ->
              socket
              |> assign(step: -2)

            {_, %{stripe_id: nil}} ->
              socket
              |> assign(step: -1)

            _ ->
              product_display =
                case product.designs.display do
                  0 -> "front"
                  1 -> "back"
                end

              now = NaiveDateTime.utc_now()

              days_remaining =
                NaiveDateTime.diff(
                  product.campaign_duration_timestamp,
                  now,
                  :day
                )

              top_3_other_products = Products.top_3_other_products(product)
              artist_href = URI.encode_query(%{"user_name" => product.user_name})
              artist_href = "/artist?#{artist_href}"

              socket
              |> assign(product_display: product_display)
              |> assign(product_days_remaining: days_remaining)
              |> assign(top_3_other_products: top_3_other_products)
              |> assign(artist_href: artist_href)
          end

        socket
        |> assign(seller: seller)
        |> assign(product: product)
        |> assign(waiting: false)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("open-mobile-header", _, socket) do
    socket =
      socket
      |> assign(mobile_header_open: true)

    {:noreply, socket}
  end

  def handle_event("close-mobile-header", _, socket) do
    socket =
      socket
      |> assign(mobile_header_open: false)

    {:noreply, socket}
  end

  def handle_event("product-href", %{"product-id" => product_id}, socket) do
    params = %{"product-id" => product_id}
    url = URI.encode_query(params)
    {:noreply, push_navigate(socket, to: "/product?#{url}")}
  end

  def handle_event("checkout-href", _, socket) do
    socket =
      socket
      |> push_navigate(to: ~p"/checkout")

    {:noreply, socket}
  end

  def handle_event("add-to-cart", _, socket) do
    cart = socket.assigns.cart
    product = socket.assigns.product
    size = socket.assigns.cart_product_size

    item = %{
      product: product,
      size: size,
      quantity: 1,
      available: true
    }

    cart = [item | cart]
    cart = Enum.uniq_by(cart, fn i -> "#{i.product.id}-#{i.size}" end)
    IO.inspect(cart)

    socket =
      socket
      |> push_event(
        "write-and-checkout",
        %{
          key: @local_storage_key,
          data: serialize_to_token(cart)
        }
      )
      |> assign(cart: cart)
      |> assign(already_in_cart: true)

    {:noreply, socket}
  end

  def handle_event("checkout", _, socket) do
    socket =
      socket
      |> push_navigate(to: "/checkout")

    {:noreply, socket}
  end

  def handle_event("change-size", %{"size" => size}, socket) do
    socket =
      socket
      |> assign(cart_product_size: size)

    {:noreply, socket}
  end

  defp serialize_to_token(state_data) do
    salt = Application.get_env(:plaza, PlazaWeb.Endpoint)[:live_view][:signing_salt]
    Phoenix.Token.encrypt(PlazaWeb.Endpoint, salt, state_data)
  end

  def handle_event("read-cart", token_data, socket) when is_binary(token_data) do
    socket =
      case restore_from_token(token_data) do
        {:ok, nil} ->
          # do nothing with the previous state
          socket

        {:ok, restored} ->
          product_id = socket.assigns.product.id
          already_in_cart = Enum.any?(restored, fn item -> item.product.id == product_id end)

          socket
          |> assign(cart: restored)
          |> assign(already_in_cart: already_in_cart)

        {:error, reason} ->
          # We don't continue checking. Display error.
          # Clear the token so it doesn't keep showing an error.
          socket
          |> put_flash(:error, reason)
          |> clear_browser_storage()
      end

    {:noreply, socket}
  end

  def handle_event("read-cart", _token_data, socket) do
    Logger.debug("No (valid) cart to restore")
    {:noreply, socket}
  end

  defp restore_from_token(nil), do: {:ok, nil}

  defp restore_from_token(token) do
    salt = Application.get_env(:plaza, PlazaWeb.Endpoint)[:live_view][:signing_salt]
    # Max age is 1 day. 86,400 seconds
    case Phoenix.Token.decrypt(PlazaWeb.Endpoint, salt, token, max_age: 86_400) do
      {:ok, data} ->
        {:ok, data}

      {:error, reason} ->
        # handles `:invalid`, `:expired` and possibly other things?
        {:error, "Failed to restore previous state. Reason: #{inspect(reason)}."}
    end
  end

  # Push a websocket event down to the browser's JS hook.
  # Clear any settings for the current my_storage_key.
  defp clear_browser_storage(socket) do
    push_event(socket, "clear", %{key: @local_storage_key})
  end

  @impl Phoenix.LiveView
  def render(%{waiting: true} = assigns) do
    ~H"""
    <div style="margin-top: 200px; margin-bottom: 200px; display: flex; justify-content: center;">
      <img src="gif/loading.gif" class="is-loading" />
    </div>
    """
  end

  def render(%{product: nil} = assigns) do
    ~H"""
    <div>
      <div style="display: flex; justify-content: center;">
        product does not exist
      </div>
    </div>
    """
  end

  def render(%{product: product, step: -1} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div>
          <ProductComponent.product product={product} meta={true} disabled={true} />
        </div>
        <div>
          this seller has not finished registration yet
        </div>
      </div>
    </div>
    """
  end

  def render(%{product: product, step: -2} = assigns) do
    ~H"""
    <div class="has-font-3" style="margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <ProductComponent.product product={product} meta={true} disabled={true} style="width: 350px;" />
      </div>
    </div>
    """
  end

  def render(%{product: product, seller: seller} = assigns) do
    ~H"""
    <div class="is-product-page-desktop has-font-3" style="margin-top: 50px;">
      <div style="display: flex; justify-content: center;">
        <div style="max-width: 1750px; width: 100%; margin-left: 10px; margin-right: 10px;">
          <div style="display: flex; margin-bottom: 86px;">
            <div style="margin-right: 10px;">
              <img src={@product.mocks.front} />
            </div>
            <div style="margin-right: 50px;">
              <img src={@product.mocks.back} />
            </div>
            <div style="display: flex; flex-direction: column;">
              <div style="font-size: 36px; margin-bottom: 12px;">
                <%= @product.name %>
              </div>
              <div style="color: grey; font-size: 24px; width: 225px; margin-bottom: 38px;">
                <%= "Disponível por mais #{@product_days_remaining} dias" %>
              </div>
              <div style="font-size: 36px; margin-bottom: 24px;">
                <%= "R$ #{@product.price |> Float.to_string() |> String.replace(".", ",")}" %>
              </div>
              <div style="font-size: 28px; color: grey; text-decoration: underline; margin-bottom: 27px;">
                <p>
                  <.link navigate={@artist_href}>
                    <%= @product.user_name %>
                  </.link>
                </p>
              </div>
              <div
                :if={@product.description}
                style="font-size: 26px; overflow-y: auto; text-wrap: wrap; width: 217px; height: 120px; margin-bottom: 49px;"
              >
                <%= @product.description %>
              </div>
              <div style="font-size: 22px; line-height: 24px; margin-bottom: 49px;">
                <div>
                  100% Algodão
                </div>
                <div>
                  Feito no Brasil
                </div>
                <div>
                  <%= "SKU: #{@product.id}" %>
                </div>
              </div>
              <div style="margin-top: auto;">
                <div style="display: flex; width: 229px; margin-bottom: 91px;">
                  <button class="has-font-3" phx-click="change-size" phx-value-size="p">
                    <img :if={@cart_product_size != "p"} src="/svg/p.svg" />
                    <img :if={@cart_product_size == "p"} src="/svg/p-selected.svg" />
                  </button>
                  <img src="/svg/forward-slash.svg" style="margin-left: 5px; margin-right: 5px;" />
                  <button class="has-font-3" phx-click="change-size" phx-value-size="m">
                    <img :if={@cart_product_size != "m"} src="/svg/m.svg" />
                    <img :if={@cart_product_size == "m"} src="/svg/m-selected.svg" />
                  </button>
                  <img src="/svg/forward-slash.svg" style="margin-left: 5px; margin-right: 5px;" />
                  <button class="has-font-3" phx-click="change-size" phx-value-size="g">
                    <img :if={@cart_product_size != "g"} src="/svg/g.svg" />
                    <img :if={@cart_product_size == "g"} src="/svg/g-selected.svg" />
                  </button>
                  <img src="/svg/forward-slash.svg" style="margin-left: 5px; margin-right: 5px;" />
                  <button class="has-font-3" phx-click="change-size" phx-value-size="gg">
                    <img :if={@cart_product_size != "gg"} src="/svg/gg.svg" />
                    <img :if={@cart_product_size == "gg"} src="/svg/gg-selected.svg" />
                  </button>
                  <img src="/svg/forward-slash.svg" style="margin-left: 5px; margin-right: 5px;" />
                  <button class="has-font-3" phx-click="change-size" phx-value-size="xgg">
                    <img :if={@cart_product_size != "xgg"} src="/svg/xgg.svg" />
                    <img :if={@cart_product_size == "xgg"} src="/svg/xgg-selected.svg" />
                  </button>
                </div>
                <div>
                  <button phx-click="add-to-cart">
                    <img src="/svg/comprar.svg" />
                  </button>
                </div>
              </div>
            </div>
          </div>
          <div style="display: flex; font-size: 32px; text-decoration: underline; color: grey; margin-bottom: 88px;">
            <a style="color: grey; margin-right: 22px;">Guia de tamanhos</a>
            <a style="color: grey; margin-right: 22px;">Como funciona a entrega</a>
            <a style="color: grey; margin-right: 22px;">Instruções de Lavagem</a>
            <a style="color: grey;">Termos e condições</a>
          </div>
          <div
            :if={!Enum.empty?(@top_3_other_products)}
            class="has-font-3"
            style="border-top: 1px solid grey;"
          >
            <div style="font-size: 36px; margin-top: 40px; margin-bottom: 41.5px;">
              Outros produtos parecidos
            </div>
            <div style="margin-bottom: 100px;">
              <ProductComponent.products3 products={@top_3_other_products} />
            </div>
            <div style="display: flex; justify-content: center; margin-bottom: 100px;">
              <.link navigate="/" style="font-size: 28px; text-decoration: underline;">
                Voltar para loja principal
              </.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="is-product-page-mobile has-font-3" style="margin-top: 50px;">
      <div style="margin-left: 25px; margin-right: 25px;">
        <div style="display: flex; justify-content: center; font-size: 32px;">
          <div>
            <%= @product.name %>
          </div>
          <div style="margin-left: auto;">
            <%= "R$ #{@product.price |> Float.to_string() |> String.replace(".", ",")}" %>
          </div>
        </div>
        <div style="color: grey; text-decoration: underline; font-size: 28px; position: relative; bottom: 15px;">
          <p>
            <.link navigate={@artist_href}>
              <%= @product.user_name %>
            </.link>
          </p>
        </div>
        <div>
          <button phx-click="change-product-display">
            <img src={
              if @product_display == "front", do: @product.mocks.front, else: @product.mocks.back
            } />
          </button>
        </div>
        <div style="width: 150px;">
          <button phx-click="change-product-display">
            <img src={
              if @product_display == "front", do: @product.mocks.back, else: @product.mocks.front
            } />
          </button>
        </div>
        <div :if={!@already_in_cart}>
          <div style="display: flex;">
            <div style="font-size: 22px; margin-top: 25px; position: relative; right: 10px;">
              <div style="display: inline-block;">
                <button
                  class="has-font-3"
                  phx-click="change-size"
                  phx-value-size="p"
                  style={if @cart_product_size == "p", do: "margin-right: 9px;"}
                >
                  <div style="position: absolute;">
                    <img
                      :if={@cart_product_size == "p"}
                      src="svg/yellow-circle.svg"
                      style="position: relative; width: 35px; right: 13px;"
                    />
                  </div>
                  <div style="position: relative;">
                    P
                  </div>
                </button>
                /
                <button
                  class="has-font-3"
                  phx-click="change-size"
                  phx-value-size="m"
                  style={if @cart_product_size == "m", do: "margin-right: 7px; margin-left: 7px;"}
                >
                  <div style="position: absolute;">
                    <img
                      :if={@cart_product_size == "m"}
                      src="svg/yellow-circle.svg"
                      style="position: relative; width: 35px; right: 10px;"
                    />
                  </div>
                  <div style="position: relative;">
                    M
                  </div>
                </button>
                /
                <button
                  class="has-font-3"
                  phx-click="change-size"
                  phx-value-size="g"
                  style={if @cart_product_size == "g", do: "margin-right: 7px; margin-left: 8px;"}
                >
                  <div style="position: absolute;">
                    <img
                      :if={@cart_product_size == "g"}
                      src="svg/yellow-circle.svg"
                      style="position: relative; width: 35px; right: 11px;"
                    />
                  </div>
                  <div style="position: relative;">
                    G
                  </div>
                </button>
                /
                <button
                  class="has-font-3"
                  phx-click="change-size"
                  phx-value-size="gg"
                  style={if @cart_product_size == "gg", do: "margin-right: 3px; margin-left: 3px;"}
                >
                  <div style="position: absolute;">
                    <img
                      :if={@cart_product_size == "gg"}
                      src="svg/yellow-circle.svg"
                      style="position: relative; width: 35px; right: 4px;"
                    />
                  </div>
                  <div style="position: relative;">
                    GG
                  </div>
                </button>
                /
                <button
                  class="has-font-3"
                  phx-click="change-size"
                  phx-value-size="xgg"
                  style={if @cart_product_size == "xgg", do: "font-size: 18px; width: 35px;"}
                >
                  <div style="position: absolute;">
                    <img
                      :if={@cart_product_size == "xgg"}
                      src="svg/yellow-circle.svg"
                      style="position: relative; bottom: 4px;"
                    />
                  </div>
                  <div style="position: relative;">
                    XGG
                  </div>
                </button>
              </div>
            </div>
            <div style="margin-left: auto; position: relative; left: 10px; top: 10px;">
              <button phx-click="add-to-cart" style="width: 145px;">
                <img src="svg/yellow-ellipse.svg" />
                <div class="has-font-3" style="position: relative; bottom: 65px; font-size: 34px;">
                  comprar
                </div>
              </button>
            </div>
          </div>
        </div>
        <div :if={@already_in_cart}>
          <div style="text-decoration: underline; font-size: 24px; display: flex; justify-content: right;">
            <.link navigate="/">loja</.link>
          </div>
          <div style="position: relative; top: 10px; display: flex; justify-content: right;">
            <button phx-click="checkout-href">
              <img src="svg/yellow-ellipse.svg" style="width: 175px;" />
              <div class="has-font-3" style="position: relative; bottom: 73px; font-size: 34px;">
                carrinho
              </div>
            </button>
          </div>
        </div>
        <div style="color: grey; text-align: center; margin-top: 10px; margin-bottom: 20px;">
          <%= "Este produto está disponível por mais #{@product_days_remaining} dias" %>
        </div>
        <div style="font-size: 28px; margin-bottom: 50px;">
          <%= @product.description %>
        </div>
        <div style="font-size: 22px; line-height: 24px; margin-bottom: 50px;">
          <div>
            Camiseta de algodão
          </div>
          <div>
            Cor: Branco
          </div>
          <div>
            100% Algodão
          </div>
          <div>
            Feito no Brasil
          </div>
          <div>
            <%= "SKU: #{@product.id}" %>
          </div>
        </div>
      </div>
      <div :if={!Enum.empty?(@top_3_other_products)} style="margin-bottom: 450px;">
        <div style="font-size: 28px; margin-bottom: 10px; margin-left: 20px;">
          Outros produtos parecidos
        </div>
        <div
          :for={{product, index} <- Enum.with_index(@top_3_other_products)}
          style="margin-bottom: 100px; margin-left: 20px; margin-right: 20px;"
        >
          <ProductComponent.product product={product} meta={true} disabled={false} />
        </div>
      </div>
      <div :if={Enum.empty?(@top_3_other_products)} style="margin-bottom: 200px;"></div>
    </div>
    """
  end
end
