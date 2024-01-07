defmodule PlazaWeb.Header.MobileHeader do
  use Phoenix.LiveComponent

  def handle_event("open-header", _, socket) do
    socket =
      socket
      |> assign(open: true)

    {:noreply, socket}
  end

  def handle_event("close-header", _, socket) do
    socket =
      socket
      |> assign(open: false)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div id="mobile-header-target">
      <nav :if={!@open} class="is-navbar-mobile-closed" style="display: flex;">
        <div style="margin-left: auto; margin-right: 50px; display: flex; flex-direction: column; justify-content: center; height: 100px;">
          <button
            class="has-font-3"
            style="font-size: 32px;"
            phx-click="open-header"
            phx-target={@myself}
          >
            open header
          </button>
        </div>
      </nav>
      <nav :if={@open} class="is-navbar-mobile-open" style="display: flex; justify-content: center;">
        <div style="display: flex; flex-direction: column; align-items: center;">
          <div>plazaaaaa</div>
          <div>
            <.link :if={@selected} navigate="/">
              loja
              <div style="position: absolute;">
                <div style="position: relative; left: 2px;">
                  <img src="/svg/yellow-circle.svg" />
                </div>
              </div>
            </.link>
            <.link :if={!@selected} navigate="/">
              loja
            </.link>
          </div>
          <div>
            <div class="has-dark-gray-text">buscar</div>
          </div>
          <div>
            <%= render_slot(@right) %>
          </div>
        </div>
      </nav>
    </div>
    """
  end
end
