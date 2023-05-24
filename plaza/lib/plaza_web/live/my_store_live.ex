defmodule PlazaWeb.MyStoreLive do
  use PlazaWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(header: :my_store)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <div class="has-font-3" style="display: inline-block;">
        <div class="mb-large">
          <img src="images/pep.png" style="width: 377px;" />
        </div>
        <div style="position: relative; left: 61px;">
          <div class="is-size-5" style="text-decoration: underline; margin-bottom: 33px;">
            username
          </div>
          <div></div>
        </div>
      </div>
    </div>
    """
  end
end
