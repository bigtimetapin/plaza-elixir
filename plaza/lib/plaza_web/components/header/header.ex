defmodule PlazaWeb.Header do
  use Phoenix.Component

  def get(%{header: header}) do
    header
  end

  def get(_) do
    :landing
  end

  def header(%{header: :landing, my_products: nil} = assigns) do
    ~H"""
    <.landing>
      <:store>
        <.no_store_yet_href />
      </:store>
    </.landing>
    """
  end

  def header(%{header: :landing, my_products: []} = assigns) do
    ~H"""
    <.landing>
      <:store>
        <.no_store_yet_href />
      </:store>
    </.landing>
    """
  end

  def header(%{header: :landing, my_products: _} = assigns) do
    ~H"""
    <.landing>
      <:store>
        <.my_store_href />
      </:store>
    </.landing>
    """
  end

  def header(%{header: :upload} = assigns) do
    ~H"""
    <.upload />
    """
  end

  def header(%{header: :my_store} = assigns) do
    ~H"""
    <.my_store />
    """
  end

  slot :store, required: true

  defp landing(assigns) do
    ~H"""
    <.left>
      <:right>
        <div class="level-item pr-xmedium">
          <div class="is-search-bar-1">
            <div class="has-dark-gray-text ml-xxsmall">buscar artista</div>
          </div>
        </div>
        <div class="level-item pr-xmedium">
          <%= render_slot(@store) %>
        </div>
        <div class="level-item pr-xmedium">registre-se</div>
        <div class="level-item">carrinho</div>
      </:right>
    </.left>
    """
  end

  defp my_store_href(assigns) do
    ~H"""
    <.link navigate="/my-store">
      minha loja
    </.link>
    """
  end

  defp no_store_yet_href(assigns) do
    ~H"""
    <.link navigate="/upload">
      quero vender
    </.link>
    """
  end

  defp upload(assigns) do
    ~H"""
    <.left>
      <:right>
        <div class="level-item pr-xxsmall">envie seu design</div>
        <.seperator />
        <div class="level-item pr-xxsmall">escolha seu produto</div>
        <.seperator />
        <div class="level-item pr-xxsmall">calcule sue lucro</div>
        <.seperator />
        <div class="level-item">publique sua loja</div>
      </:right>
    </.left>
    """
  end

  defp my_store(assigns) do
    ~H"""
    <.left>
      <:right>
        <div class="level-item pr-xxsmall">
          <div>
            Loja
          </div>
        </div>
        <.seperator />
        <div class="level-item pr-xxsmall">
          <div>
            Minha loja
          </div>
          <div>
            <img
              src="svg/yellow-circle.svg"
              style="position: relative; width: 33px; top: 45px; right: 70px;"
            />
          </div>
        </div>
      </:right>
    </.left>
    """
  end

  slot :right, required: true

  defp left(assigns) do
    ~H"""
    <div class="hero-head has-font-3">
      <div class="is-navbar">
        <nav class="level is-navbar-child" style="position: relative; top: 20px;">
          <div class="level-left">
            <div class="level-item">
              <div class="is-size-1-desktop is-size-2-touch">plazaaaaa</div>
            </div>
          </div>
          <div class="level-right is-size-5">
            <%= render_slot(@right) %>
          </div>
        </nav>
      </div>
    </div>
    """
  end

  defp seperator(assigns) do
    ~H"""
    <div class="level-item pr-xxsmall">
      <div class="is-header-seperator" />
    </div>
    """
  end
end
