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

  ## @site "http://localhost:4000"
  @site "https://plazaaaaa-solitary-snowflake-7144-summer-wave-9195.fly.dev"

  @local_storage_key "plaza-checkout-cart"

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket =
      if connected?(socket) do
        socket
        |> assign(cart: [])
        |> assign(cart_product_size: "m")
        |> assign(cart_product_quantity: 1)
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
    quantity = socket.assigns.cart_product_quantity

    item = %{
      product: product,
      size: size,
      quantity: quantity,
      available: true
    }

    cart = [item | cart]
    cart = Enum.uniq_by(cart, fn i -> i.product.id end)

    socket =
      socket
      |> push_event(
        "write",
        %{
          key: @local_storage_key,
          data: serialize_to_token(cart)
        }
      )
      |> assign(cart: cart)
      |> assign(already_in_cart: true)

    {:noreply, socket}
  end

  def handle_event("change-product-display", _, socket) do
    side =
      case socket.assigns.product_display do
        "front" -> "back"
        "back" -> "front"
      end

    socket =
      socket
      |> assign(product_display: side)

    {:noreply, socket}
  end

  def handle_event("change-size", %{"size" => size}, socket) do
    socket =
      socket
      |> assign(cart_product_size: size)

    {:noreply, socket}
  end

  def handle_event("change-quantity", %{"op" => operator}, socket) do
    quantity = socket.assigns.cart_product_quantity

    quantity =
      case operator do
        "add" -> quantity + 1
        "subtract" -> quantity - 1
      end

    socket =
      socket
      |> assign(cart_product_quantity: quantity)

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
    <div style="margin-top: 200px; display: flex; justify-content: center;">
      <img src="gif/loading.gif" />
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
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div>
          <ProductComponent.product product={product} meta={true} disabled={true} />
        </div>
        <div>
          this product is no longer available
        </div>
      </div>
    </div>
    """
  end

  def render(%{product: product, seller: seller} = assigns) do
    ~H"""
    <div class="is-product-page-desktop" style="margin-top: 150px;">
      <div
        class="has-font-3 columns is-desktop"
        style="margin-left: 100px; margin-right: 100px; margin-top: 50px; margin-bottom: 150px; max-width: 2000px;"
      >
        <div class="column">
          <div style="display: flex; flex-direction: column; height: 100%;">
            <div style="font-size: 34px;">
              <%= @product.name %>
            </div>
            <div style="font-size: 26px; color: grey; text-decoration: underline; margin-bottom: 25px;">
              <p>
                <.link navigate={@artist_href}>
                  <%= @product.user_name %>
                </.link>
              </p>
            </div>
            <div
              :if={@product.description}
              style="font-size: 22px; overflow-y: auto; text-wrap: wrap; width: 210px; height: 210px;"
            >
              <%= @product.description %>
            </div>
            <div style="margin-top: auto; font-size: 22px; line-height: 24px;">
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
                SKU: 222270M213012
              </div>
            </div>
          </div>
        </div>
        <div class="column">
          <div style="display: flex;">
            <div>
              <div style="width: 450px;">
                <button phx-click="change-product-display">
                  <img src={
                    if @product_display == "front",
                      do: @product.mocks.front,
                      else: @product.mocks.back
                  } />
                </button>
                <div style="position: absolute;">
                  <div style="color: grey; width: 450px; text-align: center; margin-top: 10px;">
                    <%= "Este produto está disponível por mais #{@product_days_remaining} dias" %>
                  </div>
                </div>
              </div>
            </div>
            <div style="margin-left: 10px; display: flex; flex-direction: column;">
              <div style="width: 100px; margin-top: auto;">
                <button phx-click="change-product-display">
                  <img src={
                    if @product_display == "front",
                      do: @product.mocks.back,
                      else: @product.mocks.front
                  } />
                </button>
              </div>
            </div>
          </div>
        </div>
        <div class="column" style="margin-top: auto;">
          <div style="display: flex;">
            <div style="margin-left: auto; display: flex; flex-direction: column;">
              <div style="margin-top: auto;">
                <div :if={!@already_in_cart}>
                  <div style="font-size: 28px;">
                    <div style="display: flex; width: 295px;">
                      <div style="margin-left: 15px;">
                        <button phx-click="change-quantity" phx-value-op="add">
                          +
                        </button>
                        <button
                          :if={@cart_product_quantity > 1}
                          phx-click="change-quantity"
                          phx-value-op="subtract"
                        >
                          -
                        </button>
                      </div>
                      <div style="text-decoration: underline; margin-left: 5px;">
                        <%= "Qtd. #{@cart_product_quantity}" %>
                      </div>
                      <div style="margin-left: auto; margin-right: 15px;">
                        <%= "R$ #{@product.price |> Float.to_string() |> String.replace(".", ",")}" %>
                      </div>
                    </div>
                  </div>
                  <div style="font-size: 28px;">
                    <div style="display: inline-block;">
                      <button
                        class="has-font-3"
                        phx-click="change-size"
                        phx-value-size="p"
                        style="width: 43px;"
                      >
                        <div style="position: absolute;">
                          <img :if={@cart_product_size == "p"} src="svg/yellow-circle.svg" />
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
                        style="width: 43px;"
                      >
                        <div style="position: absolute;">
                          <img :if={@cart_product_size == "m"} src="svg/yellow-circle.svg" />
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
                        style="width: 43px;"
                      >
                        <div style="position: absolute;">
                          <img :if={@cart_product_size == "g"} src="svg/yellow-circle.svg" />
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
                        style="width: 43px;"
                      >
                        <div style="position: absolute;">
                          <img :if={@cart_product_size == "gg"} src="svg/yellow-circle.svg" />
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
                        style={
                          if @cart_product_size == "xgg",
                            do: "font-size: 22px; width: 43px;",
                            else: "width: 43px;"
                        }
                      >
                        <div style="position: absolute;">
                          <img
                            :if={@cart_product_size == "xgg"}
                            src="svg/yellow-circle.svg"
                            style="position: relative; bottom: 5px;"
                          />
                        </div>
                        <div style="position: relative;">
                          XGG
                        </div>
                      </button>
                    </div>
                  </div>
                  <div style="display: flex; justify-content: center; position: relative; top: 25px;">
                    <button phx-click="add-to-cart">
                      <img src="svg/yellow-ellipse.svg" />
                      <div
                        class="has-font-3"
                        style="position: relative; bottom: 79px; font-size: 36px;"
                      >
                        Comprar
                      </div>
                    </button>
                  </div>
                </div>
                <div :if={@already_in_cart}>
                  <div style="text-decoration: underline; font-size: 24px;">
                    <.link navigate="/">Loja</.link>
                  </div>
                  <div style="position: relative; top: 10px;">
                    <button phx-click="checkout-href">
                      <img src="svg/yellow-ellipse.svg" />
                      <div
                        class="has-font-3"
                        style="position: relative; bottom: 79px; font-size: 36px;"
                      >
                        Carrinho
                      </div>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div
        :if={!Enum.empty?(@top_3_other_products)}
        class="has-font-3"
        style="border-top: 1px solid grey;"
      >
        <div style="margin-left: 100px;">
          <div style="font-size: 28px; margin-top: 25px; margin-bottom: 10px;">
            Outros produtos parecidos
          </div>
          <div style="display: flex; justify-content: center; margin-bottom: 100px;">
            <div :for={product <- @top_3_other_products} style="width: 100%;">
              <ProductComponent.product product={product} meta={true} disabled={false} />
            </div>
          </div>
          <div style="display: flex; justify-content: center; margin-bottom: 100px;">
            <.link navigate="/" style="font-size: 28px; text-decoration: underline;">
              Voltar para loja principal
            </.link>
          </div>
        </div>
      </div>
    </div>
    <div class="is-product-page-mobile has-font-3" style="margin-top: 150px;">
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
          <div style="font-size: 32px; margin-top: 25px;">
            <div style="display: flex;">
              <div>
                <button phx-click="change-quantity" phx-value-op="add">
                  +
                </button>
                <button
                  :if={@cart_product_quantity > 1}
                  phx-click="change-quantity"
                  phx-value-op="subtract"
                >
                  -
                </button>
              </div>
              <div style="text-decoration: underline; margin-left: 5px;">
                <%= "Qtd. #{@cart_product_quantity}" %>
              </div>
              <div style="margin-left: auto; margin-right: 47px;">
                <%= "R$ #{@product.price |> Float.to_string() |> String.replace(".", ",")}" %>
              </div>
            </div>
          </div>
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
                <div class="has-font-3" style="position: relative; bottom: 63px; font-size: 34px;">
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
            SKU: 222270M213012
          </div>
        </div>
      </div>
      <div :if={!Enum.empty?(@top_3_other_products)} style="margin-bottom: 450px;">
        <div style="font-size: 28px; margin-bottom: 10px; margin-left: 20px;">
          Outros produtos parecidos
        </div>
        <div
          :for={{product, index} <- Enum.with_index(@top_3_other_products)}
          style="margin-bottom: 100px;"
        >
          <ProductComponent.product product={product} meta={true} disabled={false} />
        </div>
      </div>
      <div :if={Enum.empty?(@top_3_other_products)} style="margin-bottom: 200px;"></div>
    </div>
    """
  end
end
