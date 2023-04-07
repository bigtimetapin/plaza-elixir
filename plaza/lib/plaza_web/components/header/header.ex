defmodule PlazaWeb.Header do
  use Phoenix.Component

  def landing(assigns) do
    ~H"""
    <.left>
      <:right>
        <div class="level-item pr-xmedium">
          <div class="is-search-bar-1">
            <div class="has-dark-gray-text ml-xxsmall">buscar artista</div>
          </div>
        </div>
        <div class="level-item pr-xmedium">quero vender</div>
        <div class="level-item pr-xmedium">registre-se</div>
        <div class="level-item">carrinho</div>
      </:right>
    </.left>
    """
  end

  slot :right, required: true

  defp left(assigns) do
    ~H"""
    <div class="hero-head">
      <div class="is-navbar">
        <nav class="level is-navbar-child">
          <div class="level-left">
            <div class="level-item">
              <div class="is-size-1-desktop is-size-2-touch">Plaza</div>
            </div>
          </div>
          <div class="level-right has-font-3 is-size-8">
            <%= render_slot(@right) %>
          </div>
        </nav>
      </div>
    </div>
    """
  end
end
