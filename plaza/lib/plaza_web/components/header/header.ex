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
        <div class="level-item pr-xmedium">loja</div>
        <div class="level-item pr-xmedium">
          <%= render_slot(@store) %>
        </div>
        <div class="level-item pr-xmedium">carrinho</div>
        <div class="has-dark-gray-text">buscar</div>
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
        <div class="level-item pr-xmedium">loja</div>
        <div class="level-item pr-small">
          <div>
            quero vender
          </div>
          <div style="position: relative; width: 35px; top: 45px; right: 93px;">
            <img src="svg/yellow-circle.svg" />
          </div>
        </div>
        <div class="level-item pr-xmedium">carrinho</div>
        <div class="has-dark-gray-text">buscar</div>
      </:right>
    </.left>
    """
  end

  defp my_store(assigns) do
    ~H"""
    <.left>
      <:right>
        <div class="level-item pr-small">
          <div>
            Loja
          </div>
        </div>
        <div class="level-item pl-medium pr-small">
          <div>
            Minha loja
          </div>
          <div style="position: relative; width: 33px; top: 45px; right: 70px;">
            <img src="svg/yellow-circle.svg" />
          </div>
        </div>
        <div class="level-item">
          <div>
            Conta
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
end
