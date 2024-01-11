defmodule PlazaWeb.CodecLive do
  use PlazaWeb, :live_view

  require Logger

  @impl true
  def handle_params(params, _, socket) do
    # Only try to talk to the client when the websocket
    # is setup. Not on the initial "static" render.
    new_socket =
      if connected?(socket) do
        # This represents some meaningful key to your LiveView that you can
        # store and restore state using. Perhaps an ID from the page
        # the user is visiting?
        my_storage_key = "a-relevant-value-from-somewhere"
        # For handle_params, it could be
        # my_storage_key = params["id"]

        socket
        |> assign(:my_storage_key, my_storage_key)
        # request the browser to restore any state it has for this key.
        |> push_event("restore", %{key: my_storage_key, event: "restoreSettings"})
      else
        socket
      end

    {:noreply, new_socket}
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

  defp serialize_to_token(state_data) do
    salt = Application.get_env(:plaza, PlazaWeb.Endpoint)[:live_view][:signing_salt]
    Phoenix.Token.encrypt(PlazaWeb.Endpoint, salt, state_data)
  end

  # Push a websocket event down to the browser's JS hook.
  # Clear any settings for the current my_storage_key.
  defp clear_browser_storage(socket) do
    push_event(socket, "clear", %{key: socket.assigns.my_storage_key})
  end

  @impl true
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

  # Pushed from JS hook. Server requests it to send up any
  # stored settings for the key.
  def handle_event("restoreSettings", token_data, socket) when is_binary(token_data) do
    socket =
      case restore_from_token(token_data) do
        {:ok, nil} ->
          # do nothing with the previous state
          socket

        {:ok, restored} ->
          socket
          |> assign(:state, restored)

        {:error, reason} ->
          # We don't continue checking. Display error.
          # Clear the token so it doesn't keep showing an error.
          socket
          |> put_flash(:error, reason)
          |> clear_browser_storage()
      end

    {:noreply, socket}
  end

  def handle_event("restoreSettings", _token_data, socket) do
    # No expected token data received from the client
    Logger.debug("No LiveView SessionStorage state to restore")
    {:noreply, socket}
  end

  def handle_event("something_happened_and_i_want_to_store", params, socket) do
    # This represents the special state you want to store. It may come from the
    # socket.assigns. It's specific to your LiveView.
    state_to_store = socket.assigns.state

    socket =
      socket
      |> push_event("store", %{
        key: socket.assigns.my_storage_key,
        data: serialize_to_token(state_to_store)
      })

    {:noreply, socket}
  end
end
