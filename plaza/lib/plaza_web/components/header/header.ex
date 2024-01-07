defmodule PlazaWeb.Header do
  use Phoenix.Component

  def get(%{header: header}) do
    header
  end

  def get(_) do
    :landing
  end

  def header(%{header: :landing, current_user: nil} = assigns) do
    ~H"""
    <.landing>
      <:login>
        <.login_href />
      </:login>
      <:store>
        <.no_store_yet_href />
      </:store>
    </.landing>
    """
  end

  def header(%{header: :landing, seller: nil} = assigns) do
    ~H"""
    <.landing>
      <:login>
        <.my_account_href />
      </:login>
      <:store>
        <.no_store_yet_href />
      </:store>
    </.landing>
    """
  end

  def header(%{header: :landing} = assigns) do
    ~H"""
    <.landing>
      <:login>
        <.my_account_href />
      </:login>
      <:store>
        <.my_store_href />
      </:store>
    </.landing>
    """
  end

  def header(%{header: :login} = assigns) do
    ~H"""
    <.left>
      <:right>
        <div class="level-item pr-xmedium">
          <div>
            log in
            <div style="position: absolute;">
              <div style="position: relative; left: 11px;">
                <img src="/svg/yellow-circle.svg" />
              </div>
            </div>
          </div>
        </div>
        <div class="level-item pr-xmedium">
          <.checkout_href />
        </div>
        <div class="level-item">
          <.no_store_yet_href />
        </div>
      </:right>
    </.left>
    """
  end

  def header(%{header: :my_store, seller: nil} = assigns) do
    ~H"""
    <.my_store>
      <:login>
        <.my_account_href />
      </:login>
      <:store>
        <.no_store_yet_selected />
      </:store>
    </.my_store>
    """
  end

  def header(%{header: :my_store} = assigns) do
    ~H"""
    <.my_store>
      <:login>
        <.my_account_href />
      </:login>
      <:store>
        <div>
          <.my_store_href />
          <div style="position: absolute;">
            <div style="position: relative; left: 35px;">
              <img src="/svg/yellow-circle.svg" />
            </div>
          </div>
        </div>
      </:store>
    </.my_store>
    """
  end

  def header(%{header: :my_account, seller: nil} = assigns) do
    ~H"""
    <.my_account>
      <:store>
        <.no_store_yet_href />
      </:store>
    </.my_account>
    """
  end

  def header(%{header: :my_account} = assigns) do
    ~H"""
    <.my_account>
      <:store>
        <.my_store_href />
      </:store>
    </.my_account>
    """
  end

  def header(%{header: :checkout, current_user: nil} = assigns) do
    ~H"""
    <.checkout>
      <:login>
        <.login_href />
      </:login>
      <:store>
        <.no_store_yet_href />
      </:store>
    </.checkout>
    """
  end

  def header(%{header: :checkout, seller: nil} = assigns) do
    ~H"""
    <.checkout>
      <:login>
        <.my_account_href />
      </:login>
      <:store>
        <.no_store_yet_href />
      </:store>
    </.checkout>
    """
  end

  def header(%{header: :checkout} = assigns) do
    ~H"""
    <.checkout>
      <:login>
        <.my_account_href />
      </:login>
      <:store>
        <.my_store_href />
      </:store>
    </.checkout>
    """
  end

  slot :login, required: true
  slot :store, required: true

  defp landing(assigns) do
    ~H"""
    <.left selected={true}>
      <:right>
        <div class="level-item pr-xmedium">
          <%= render_slot(@login) %>
        </div>
        <div class="level-item pr-xmedium">
          <.checkout_href />
        </div>
        <div class="level-item pr-xmedium">
          <%= render_slot(@store) %>
        </div>
      </:right>
    </.left>
    """
  end

  slot :login, required: true
  slot :store, required: true

  defp checkout(assigns) do
    ~H"""
    <.left selected={false}>
      <:right>
        <div class="level-item pr-xmedium">
          <%= render_slot(@login) %>
        </div>
        <div class="level-item pr-xmedium">
          <.link phx-target="#mobile-header-target" phx-click="close-header" navigate="/checkout">
            carrinho
            <div style="position: absolute;">
              <div style="position: relative; left: 26px;">
                <img src="/svg/yellow-circle.svg" />
              </div>
            </div>
          </.link>
        </div>
        <div class="level-item pr-xmedium">
          <%= render_slot(@store) %>
        </div>
      </:right>
    </.left>
    """
  end

  defp checkout_href(assigns) do
    ~H"""
    <.link phx-target="#mobile-header-target" phx-click="close-header" navigate="/checkout">
      carrinho
    </.link>
    """
  end

  defp login_href(assigns) do
    ~H"""
    <.link phx-target="#mobile-header-target" phx-click="close-header" navigate="/users/log_in">
      log in
    </.link>
    """
  end

  defp my_store_href(assigns) do
    ~H"""
    <.link phx-target="#mobile-header-target" phx-click="close-header" navigate="/my-store">
      minha loja
    </.link>
    """
  end

  defp no_store_yet_href(assigns) do
    ~H"""
    <.link phx-target="#mobile-header-target" phx-click="close-header" navigate="/upload">
      quero vender
    </.link>
    """
  end

  defp no_store_yet_selected(assigns) do
    ~H"""
    <div>
      quero vender
      <div style="position: absolute;">
        <div style="position: relative; left: 45px;">
          <img src="/svg/yellow-circle.svg" />
        </div>
      </div>
    </div>
    """
  end

  defp my_account_href(assigns) do
    ~H"""
    <.link phx-target="#mobile-header-target" phx-click="close-header" navigate="/my-account">
      conta
    </.link>
    """
  end

  slot :store, required: true

  defp my_account(assigns) do
    ~H"""
    <.left>
      <:right>
        <div class="level-item pr-xmedium">
          <div>
            <.my_account_href />
            <div style="position: absolute;">
              <div style="position: relative; left: 13px;">
                <img src="/svg/yellow-circle.svg" />
              </div>
            </div>
          </div>
        </div>
        <div class="level-item pr-xmedium">
          <.checkout_href />
        </div>
        <div class="level-item">
          <%= render_slot(@store) %>
        </div>
      </:right>
    </.left>
    """
  end

  slot :login, required: true
  slot :store, required: true

  defp my_store(assigns) do
    ~H"""
    <.left>
      <:right>
        <div class="level-item pr-xmedium">
          <%= render_slot(@login) %>
        </div>
        <div class="level-item pr-xmedium">
          <.checkout_href />
        </div>
        <div class="level-item pr-xmedium">
          <%= render_slot(@store) %>
        </div>
      </:right>
    </.left>
    """
  end

  attr :selected, :boolean, default: false
  slot :right, required: true

  defp left(assigns) do
    ~H"""
    <div class="hero-head has-font-3">
      <div class="is-navbar is-navbar-desktop">
        <nav class="level" style="position: relative; top: 20px; margin-left: 50px">
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
      <div>
        <.live_component
          module={PlazaWeb.Header.MobileHeader}
          id="mobile-header-component"
          selected={@selected}
          right={@right}
          open={false}
        />
      </div>
    </div>
    """
  end
end
