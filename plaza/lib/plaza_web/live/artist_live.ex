defmodule PlazaWeb.ArtistLive do
  use PlazaWeb, :live_view
  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      here
    </div>
    """
  end
end
