defmodule PlazaWeb.Header.MobileHeader do
  use Phoenix.LiveComponent

  ## def update(assigns, socket) do
  ##   IO.inspect(assigns)
  ##   {:ok, socket}
  ## end

  def handle_event("open-header", _, socket) do
    socket =
      socket
      |> assign(open: true)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <nav :if={!@open} style="display: flex;">
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
      <nav :if={@open} style="position: relative; top: 20px; margin-left: 50px">
        <div class="level-left">
          <div class="level-item pr-large">
            <div class="is-size-1-desktop is-size-2-touch">plazaaaaa</div>
          </div>
          <div class="level-item pr-xmedium">
            <div class="is-size-5" style="position: relative; top: 11px;">
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
          </div>
          <div class="level-item">
            <div class="is-size-5" style="position: relative; top: 11px;">
              <div class="has-dark-gray-text">buscar</div>
            </div>
          </div>
        </div>
        <div class="level-right is-size-5" style="position: relative; top: 11px;">
          <%= render_slot(@right) %>
        </div>
      </nav>
    </div>
    """
  end
end
