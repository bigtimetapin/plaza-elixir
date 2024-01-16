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

              socket
              |> assign(product_display: product_display)
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

  def handle_event("remove-from-cart", _, socket) do
    cart = socket.assigns.cart
    product = socket.assigns.product

    {_, index} =
      Enum.with_index(cart)
      |> Enum.find(fn {item, _} -> item.product.id == product.id end)

    cart = List.delete_at(cart, index)

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
      |> assign(already_in_cart: false)

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
          <ProductComponent.product product={product} meta={true} />
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
          <ProductComponent.product product={product} meta={true} />
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
    <div
      class="has-font-3"
      style="display: flex; margin-left: 100px; margin-top: 100px; margin-bottom: 250px;"
    >
      <div style="display: flex; flex-direction: column;">
        <div style="font-size: 34px;">
          <%= @product.name %>
        </div>
        <div style="font-size: 26px; color: grey; text-decoration: underline; margin-bottom: 25px;">
          <%= @product.user_name %>
        </div>
        <div style="font-size: 34px;">
          <%= @product.description %>
        </div>
        <div style="margin-top: auto; font-size: 32px;">
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
      <div style="margin-left: 100px; display: flex; flex-direction: column;">
        <div style="width: 600px;">
          <button phx-click="change-product-display">
            <img src={
              if @product_display == "front", do: @product.mocks.front, else: @product.mocks.back
            } />
          </button>
        </div>
      </div>
      <div style="margin-left: 10px; display: flex; flex-direction: column;">
        <div style="width: 100px; margin-top: auto;">
          <button phx-click="change-product-display">
            <img src={
              if @product_display == "front", do: @product.mocks.back, else: @product.mocks.front
            } />
          </button>
        </div>
      </div>
      <div style="margin-left: 100px; display: flex; flex-direction: column;">
        <div style="margin-top: auto;">
          <div :if={!@already_in_cart} style="display: flex;">
            <div>
              <button phx-click="add-to-cart">
                <img src="svg/yellow-ellipse.svg" />
                <div class="has-font-3" style="position: relative; bottom: 79px; font-size: 36px;">
                  comprar
                </div>
              </button>
            </div>
            <div style="margin-left: 10px;">
              <div>
                <button
                  phx-click="change-size"
                  phx-value-size="s"
                  style={
                    if @cart_product_size == "s",
                      do: "font-size: 44px; margin-left: 5px",
                      else: "margin-left: 5px"
                  }
                >
                  S
                </button>
                <button
                  phx-click="change-size"
                  phx-value-size="m"
                  style={
                    if @cart_product_size == "m",
                      do: "font-size: 44px; margin-left: 5px",
                      else: "margin-left: 5px"
                  }
                >
                  M
                </button>
                <button
                  phx-click="change-size"
                  phx-value-size="l"
                  style={if @cart_product_size == "l", do: "font-size: 44px;"}
                >
                  L
                </button>
              </div>
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
                <div style="border: 1px solid grey; width: 50px; text-align: center; margin-left: 5px;">
                  <%= @cart_product_quantity %>
                </div>
              </div>
            </div>
          </div>
          <div :if={@already_in_cart}>
            <div style="text-decoration: underline;">
              <.link navigate="/checkout">carrinho</.link>
            </div>
            <div style="text-decoration: underline;">
              <.link navigate="/">loja</.link>
            </div>
            <div>
              <button phx-click="remove-from-cart">
                <img src="svg/yellow-ellipse.svg" />
                <div class="has-font-3" style="position: relative; bottom: 79px; font-size: 36px;">
                  remover
                </div>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def product_view(assigns) do
    ~H"""

    """
  end
end
