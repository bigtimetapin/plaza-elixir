defmodule PlazaWeb.UploadLive do
  use PlazaWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Upload")
      |> assign(:header, :upload)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div Upload Stuff />
    """
  end
end
