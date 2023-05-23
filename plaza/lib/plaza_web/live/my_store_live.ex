defmodule PlazaWeb.MyStoreLive do
  use PlazaWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      My Store
    </div>
    """
  end
end
