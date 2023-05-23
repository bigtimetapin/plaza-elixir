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
        <.no_store_yet />
      </:store>
    </.landing>
    """
  end

  def header(%{header: :landing, my_products: []} = assigns) do
    ~H"""
    <.landing>
      <:store>
        <.no_store_yet />
      </:store>
    </.landing>
    """
  end

  def header(%{header: :landing, my_products: _} = assigns) do
    ~H"""
    <.landing>
      <:store>
        <.my_store />
      </:store>
    </.landing>
    """
  end

  def header(%{header: :upload} = assigns) do
    ~H"""
    <.upload />
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

  defp my_store(assigns) do
    ~H"""
    <.link navigate="/upload">
      minha loja
    </.link>
    """
  end

  defp no_store_yet(assigns) do
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

  slot :right, required: true

  defp left(assigns) do
    ~H"""
    <div class="hero-head has-font-3">
      <div class="is-navbar">
        <nav class="level is-navbar-child">
          <div class="level-left">
            <div class="level-item">
              <div class="is-size-3-desktop is-size-4-touch">plazaaaaa</div>
            </div>
          </div>
          <div class="level-right is-size-8">
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
