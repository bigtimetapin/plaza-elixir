defmodule PlazaWeb.CheckoutLive do
  use PlazaWeb, :live_view

  require Logger

  @local_storage_key "plaza-checkout-cart"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(cart: [])
      |> push_event(
        "read",
        %{
          key: @local_storage_key,
          event: "read-cart"
        }
      )

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
          <div :for={product <- @cart} style="display: flex;">
            <div style="width: 100px;">
              <button>
                <img src={
                  if product.designs.display == 0, do: product.mocks.front, else: product.mocks.back
                } />
              </button>
            </div>
            <div style="margin-left: 127px; font-size: 32px;">
              <%= product.name %>
            </div>
            <div style="margin-left: auto; margin-right: 10px;">
              <div style="font-size: 32px;">
                <%= "R$ #{String.replace(Float.to_string(product.price), ".", ",")}" %>
              </div>
              <div style="font-size: 28px; color: grey;">
                here
              </div>
            </div>
          </div>
        </div>
      </div>
      <div style="margin-left: 50px; font-size: 44px;">
        here
      </div>
    </div>
    """
  end
end
