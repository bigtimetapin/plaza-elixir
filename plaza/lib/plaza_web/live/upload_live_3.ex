defmodule PlazaWeb.UploadLive3 do
  use PlazaWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(step: 1)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("new-png-selected", base64, socket) do
    IO.inspect(base64)
    {:noreply, socket}
  end

  def handle_event("next", _, socket) do
    socket =
      socket
      |> assign(step: 2)

    {:noreply, socket}
  end

  def handle_event("back", _, socket) do
    socket =
      socket
      |> assign(step: 1)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(%{step: 1} = assigns) do
    ~H"""
    <div style="display: flex; justify-content: center; font-size: 24px;" class="has-font-3">
      <script id="upload-3-file-reader" phx-hook="FileReader" />
      <form>
        <input type="file" id="upload-3-file-input" accept=".png" multiple={false} />
      </form>
      <img id="upload-3-file-display" src="png/pep.png" style="width: 100px;" />
    </div>
    <button phx-click="next">
      next
    </button>
    """
  end

  def render(%{step: 2} = assigns) do
    ~H"""
    <button phx-click="back">
      back
    </button>
    """
  end
end
