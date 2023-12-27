defmodule PlazaWeb.CheckoutLive do
  use PlazaWeb, :live_view

  require Logger

  alias Plaza.Accounts

  @local_storage_key "plaza-checkout-cart"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      case connected?(socket) do
        false ->
          socket

        true ->
          seller =
            case socket.assigns.current_user do
              nil ->
                nil

              %{id: id} ->
                Accounts.get_seller_by_id(id)
            end

          socket
          |> assign(seller: seller)
          |> push_event(
            "read",
            %{
              key: @local_storage_key,
              event: "read-cart"
            }
          )
      end

    socket =
      socket
      |> assign(cart: [])
      |> assign(header: :checkout)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("read-cart", token_data, socket) when is_binary(token_data) do
    socket =
      case restore_from_token(token_data) do
        {:ok, nil} ->
          # do nothing with the previous state
          socket

        {:ok, restored} ->
          IO.inspect(restored)

          socket
          |> assign(cart: restored)

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

  defp serialize_to_token(state_data) do
    salt = Application.get_env(:plaza, PlazaWeb.Endpoint)[:live_view][:signing_salt]
    Phoenix.Token.encrypt(PlazaWeb.Endpoint, salt, state_data)
  end

  def handle_event("change-size", %{"size" => size, "product-id" => product_id}, socket) do
    cart = socket.assigns.cart
    product_id = String.to_integer(product_id)

    {item, index} =
      Enum.with_index(cart)
      |> Enum.find(fn {item, _} -> item.product.id == product_id end)

    item = %{item | size: size}
    cart = List.replace_at(cart, index, item)

    socket =
      socket
      |> assign(cart: cart)
      |> push_event(
        "write",
        %{
          key: @local_storage_key,
          data: serialize_to_token(cart)
        }
      )

    {:noreply, socket}
  end

  def handle_event("change-quantity", %{"op" => operator, "product-id" => product_id}, socket) do
    cart = socket.assigns.cart
    product_id = String.to_integer(product_id)

    {item, index} =
      Enum.with_index(cart)
      |> Enum.find(fn {item, _} -> item.product.id == product_id end)

    quantity = item.quantity

    quantity =
      case operator do
        "add" -> quantity + 1
        "subtract" -> quantity - 1
      end

    item = %{item | quantity: quantity}
    cart = List.replace_at(cart, index, item)

    socket =
      socket
      |> assign(cart: cart)
      |> push_event(
        "write",
        %{
          key: @local_storage_key,
          data: serialize_to_token(cart)
        }
      )

    {:noreply, socket}
  end

  def handle_event("remove-from-cart", %{"product-id" => product_id}, socket) do
    cart = socket.assigns.cart
    product_id = String.to_integer(product_id)

    {_, index} =
      Enum.with_index(cart)
      |> Enum.find(fn {item, _} -> item.product.id == product_id end)

    cart = List.delete_at(cart, index)

    socket =
      socket
      |> assign(cart: cart)
      |> push_event(
        "write",
        %{
          key: @local_storage_key,
          data: serialize_to_token(cart)
        }
      )

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="has-font-3" style="margin-top: 150px; margin-bottom: 150px; display: flex;">
      <div style="margin-left: 50px; font-size: 44px;">
        <div style="display: flex; border-bottom: 2px solid grey; width: 800px;">
          <div>
            carrinho
          </div>
          <div style="margin-left: 100px;">
            item
          </div>
          <div style="margin-left: auto; margin-right: 10px;">
            valor
          </div>
        </div>
        <div style="margin-top: 20px;">
          <div :for={item <- @cart} style="display: flex;">
            <div style="width: 100px;">
              <button>
                <img src={
                  if item.product.designs.display == 0,
                    do: item.product.mocks.front,
                    else: item.product.mocks.back
                } />
              </button>
            </div>
            <div style="margin-left: 127px;">
              <div style="font-size: 32px;">
                <%= item.product.name %>
              </div>
              <div style="font-size: 28px; color: grey;">
                <button
                  phx-click="change-size"
                  phx-value-size="s"
                  phx-value-product-id={item.product.id}
                  style={
                    if item.size == "s",
                      do: "font-size: 38px; margin-left: 5px",
                      else: "margin-left: 5px"
                  }
                >
                  S
                </button>
                <button
                  phx-click="change-size"
                  phx-value-size="m"
                  phx-value-product-id={item.product.id}
                  style={
                    if item.size == "m",
                      do: "font-size: 38px; margin-left: 5px",
                      else: "margin-left: 5px"
                  }
                >
                  M
                </button>
                <button
                  phx-click="change-size"
                  phx-value-size="l"
                  phx-value-product-id={item.product.id}
                  style={if item.size == "l", do: "font-size: 38px;"}
                >
                  L
                </button>
              </div>
            </div>
            <div style="margin-left: auto; margin-right: 10px;">
              <div style="font-size: 32px;">
                <%= "R$ #{String.replace(Float.to_string(item.product.price), ".", ",")}" %>
              </div>
              <div style="display: flex; font-size: 22px; margin-top: 5px;">
                <div>
                  <button
                    phx-click="change-quantity"
                    phx-value-op="add"
                    phx-value-product-id={item.product.id}
                  >
                    +
                  </button>
                  <button
                    :if={item.quantity > 1}
                    phx-click="change-quantity"
                    phx-value-op="subtract"
                    phx-value-product-id={item.product.id}
                  >
                    -
                  </button>
                </div>
                <div style="border: 1px solid grey; width: 40px; text-align: center; margin-left: 5px;">
                  <%= item.quantity %>
                </div>
              </div>
              <div>
                <button
                  style="font-size: 18px; color: grey; position: relative; bottom: 25px;"
                  phx-click="remove-from-cart"
                  phx-value-product-id={item.product.id}
                >
                  remover
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div style="margin-left: 50px; font-size: 44px;"></div>
    </div>
    """
  end
end
