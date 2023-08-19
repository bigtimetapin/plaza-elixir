defmodule PlazaWeb.ProductLive do
  use PlazaWeb, :live_view

  alias PlazaWeb.ProductComponent

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    IO.inspect(params)
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="mx-large">
      <div>
        product
      </div>
    </div>
    """
  end
end
