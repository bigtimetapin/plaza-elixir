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
    <div>
      <.landing_desktop>
        <:login>
          <.login_href />
        </:login>
        <:store>
          <.no_store_yet_href />
        </:store>
      </.landing_desktop>
      <.mobile open={@mobile_open}>
        <:landing>
          <.landing_href_selected_mobile />
        </:landing>
        <:my_account>
          <.login_href_mobile />
        </:my_account>
        <:checkout>
          <.checkout_href_mobile />
        </:checkout>
      </.mobile>
    </div>
    """
  end

  def header(%{header: :landing, seller: nil} = assigns) do
    ~H"""
    <div>
      <.landing_desktop>
        <:login>
          <.my_account_href />
        </:login>
        <:store>
          <.no_store_yet_href />
        </:store>
      </.landing_desktop>
      <.mobile open={@mobile_open}>
        <:landing>
          <.landing_href_selected_mobile />
        </:landing>
        <:my_account>
          <.my_account_href_mobile />
        </:my_account>
        <:checkout>
          <.checkout_href_mobile />
        </:checkout>
      </.mobile>
    </div>
    """
  end

  def header(%{header: :landing} = assigns) do
    ~H"""
    <div>
      <.landing_desktop>
        <:login>
          <.my_account_href />
        </:login>
        <:store>
          <.my_store_href />
        </:store>
      </.landing_desktop>
      <.mobile open={@mobile_open}>
        <:landing>
          <.landing_href_selected_mobile />
        </:landing>
        <:my_account>
          <.my_account_href_mobile />
        </:my_account>
        <:checkout>
          <.checkout_href_mobile />
        </:checkout>
      </.mobile>
    </div>
    """
  end

  def header(%{header: :login} = assigns) do
    ~H"""
    <div>
      <.left_desktop>
        <:right>
          <div class="pr-xmedium">
            <div>
              log in
            </div>
          </div>
          <div class="pr-xmedium">
            <.checkout_href />
          </div>
          <div>
            <.no_store_yet_href />
          </div>
        </:right>
      </.left_desktop>
      <.mobile open={@mobile_open}>
        <:landing>
          <.landing_href_mobile />
        </:landing>
        <:my_account>
          <.login_href_selected_mobile />
        </:my_account>
        <:checkout>
          <.checkout_href_mobile />
        </:checkout>
      </.mobile>
    </div>
    """
  end

  def header(%{header: :my_store, current_user: nil, seller: nil} = assigns) do
    ~H"""
    <div>
      <.my_store_desktop>
        <:login>
          <.login_href />
        </:login>
        <:store>
          <.no_store_yet_href_selected />
        </:store>
      </.my_store_desktop>
      <.mobile open={@mobile_open}>
        <:landing>
          <.landing_href_mobile />
        </:landing>
        <:my_account>
          <.login_href_mobile />
        </:my_account>
        <:checkout>
          <.checkout_href_mobile />
        </:checkout>
      </.mobile>
    </div>
    """
  end

  def header(%{header: :my_store, seller: nil} = assigns) do
    ~H"""
    <div>
      <.my_store_desktop>
        <:login>
          <.my_account_href />
        </:login>
        <:store>
          <.no_store_yet_href_selected />
        </:store>
      </.my_store_desktop>
      <.mobile open={@mobile_open}>
        <:landing>
          <.landing_href_mobile />
        </:landing>
        <:my_account>
          <.my_account_href_mobile />
        </:my_account>
        <:checkout>
          <.checkout_href_mobile />
        </:checkout>
      </.mobile>
    </div>
    """
  end

  def header(%{header: :my_store} = assigns) do
    ~H"""
    <div>
      <.my_store_desktop>
        <:login>
          <.my_account_href />
        </:login>
        <:store>
          <div>
            <.my_store_href />
          </div>
        </:store>
      </.my_store_desktop>
      <.mobile open={@mobile_open}>
        <:landing>
          <.landing_href_mobile />
        </:landing>
        <:my_account>
          <.my_account_href_mobile />
        </:my_account>
        <:checkout>
          <.checkout_href_mobile />
        </:checkout>
      </.mobile>
    </div>
    """
  end

  def header(%{header: :my_account, seller: nil} = assigns) do
    ~H"""
    <div>
      <.my_account_desktop>
        <:store>
          <.no_store_yet_href />
        </:store>
      </.my_account_desktop>
      <.mobile open={@mobile_open}>
        <:landing>
          <.landing_href_mobile />
        </:landing>
        <:my_account>
          <.my_account_href_selected_mobile />
        </:my_account>
        <:checkout>
          <.checkout_href_mobile />
        </:checkout>
      </.mobile>
    </div>
    """
  end

  def header(%{header: :my_account} = assigns) do
    ~H"""
    <div>
      <.my_account_desktop>
        <:store>
          <.my_store_href />
        </:store>
      </.my_account_desktop>
      <.mobile open={@mobile_open}>
        <:landing>
          <.landing_href_mobile />
        </:landing>
        <:my_account>
          <.my_account_href_selected_mobile />
        </:my_account>
        <:checkout>
          <.checkout_href_mobile />
        </:checkout>
      </.mobile>
    </div>
    """
  end

  def header(%{header: :checkout, current_user: nil} = assigns) do
    ~H"""
    <div>
      <.checkout_desktop>
        <:login>
          <.login_href />
        </:login>
        <:store>
          <.no_store_yet_href />
        </:store>
      </.checkout_desktop>
      <.mobile open={@mobile_open}>
        <:landing>
          <.landing_href_mobile />
        </:landing>
        <:my_account>
          <.login_href_mobile />
        </:my_account>
        <:checkout>
          <.checkout_href_selected_mobile />
        </:checkout>
      </.mobile>
    </div>
    """
  end

  def header(%{header: :checkout, seller: nil} = assigns) do
    ~H"""
    <div>
      <.checkout_desktop>
        <:login>
          <.my_account_href />
        </:login>
        <:store>
          <.no_store_yet_href />
        </:store>
      </.checkout_desktop>
      <.mobile open={@mobile_open}>
        <:landing>
          <.landing_href_mobile />
        </:landing>
        <:my_account>
          <.my_account_href_mobile />
        </:my_account>
        <:checkout>
          <.checkout_href_selected_mobile />
        </:checkout>
      </.mobile>
    </div>
    """
  end

  def header(%{header: :checkout} = assigns) do
    ~H"""
    <div>
      <.checkout_desktop>
        <:login>
          <.my_account_href />
        </:login>
        <:store>
          <.my_store_href />
        </:store>
      </.checkout_desktop>
      <.mobile open={@mobile_open}>
        <:landing>
          <.landing_href_mobile />
        </:landing>
        <:my_account>
          <.my_account_href_mobile />
        </:my_account>
        <:checkout>
          <.checkout_href_selected_mobile />
        </:checkout>
      </.mobile>
    </div>
    """
  end

  slot :login, required: true
  slot :store, required: true

  defp landing_desktop(assigns) do
    ~H"""
    <.left_desktop>
      <:right>
        <div class="pr-xmedium">
          <%= render_slot(@login) %>
        </div>
        <div class="pr-xmedium">
          <.checkout_href />
        </div>
        <div>
          <%= render_slot(@store) %>
        </div>
      </:right>
    </.left_desktop>
    """
  end

  slot :login, required: true
  slot :store, required: true

  defp checkout_desktop(assigns) do
    ~H"""
    <.left_desktop>
      <:right>
        <div class="pr-xmedium">
          <%= render_slot(@login) %>
        </div>
        <div class="pr-xmedium">
          <.link phx-click="close-mobile-header" navigate="/checkout">
            carrinho
          </.link>
        </div>
        <div>
          <%= render_slot(@store) %>
        </div>
      </:right>
    </.left_desktop>
    """
  end

  slot :store, required: true

  defp my_account_desktop(assigns) do
    ~H"""
    <.left_desktop>
      <:right>
        <div class="pr-xmedium">
          <div>
            <.my_account_href />
          </div>
        </div>
        <div class="pr-xmedium">
          <.checkout_href />
        </div>
        <div>
          <%= render_slot(@store) %>
        </div>
      </:right>
    </.left_desktop>
    """
  end

  slot :login, required: true
  slot :store, required: true

  defp my_store_desktop(assigns) do
    ~H"""
    <.left_desktop>
      <:right>
        <div class="pr-xmedium">
          <%= render_slot(@login) %>
        </div>
        <div class="pr-xmedium">
          <.checkout_href />
        </div>
        <div>
          <%= render_slot(@store) %>
        </div>
      </:right>
    </.left_desktop>
    """
  end

  attr :header, :atom, required: true
  slot :right, required: true

  defp left_desktop(assigns) do
    ~H"""
    <div class="hero-head has-font-3">
      <div class="is-navbar is-navbar-desktop">
        <nav style="display: flex; justify-content: center; margin-left: 10px; margin-right: 10px;">
          <div style="display: flex; max-width: 1750px; width: 100%;">
            <div style="font-size: 72px;">
              <div style="display: flex;">
                <div style="align-self: center; margin-right: 20px; margin-top: 15px;">
                  <img src="/svg/yellow-circle.svg" />
                </div>
                <.link navigate="/">
                  plazaaaaa
                </.link>
              </div>
            </div>
            <div class="is-size-5" style="margin-left: auto; align-self: center; margin-top: 20px;">
              <div style="display: flex;">
                <%= render_slot(@right) %>
              </div>
            </div>
          </div>
        </nav>
      </div>
    </div>
    """
  end

  defp mobile(assigns) do
    ~H"""
    <div>
      <nav :if={!@open} class="is-navbar-mobile-closed">
        <div style="display: flex;">
          <div class="has-font-3" style="font-size: 60px; margin-right: auto; margin-left: 25px;">
            <.link navigate="/">
              plazaaaaa
            </.link>
          </div>
          <div style="margin-left: auto; margin-right: 25px;">
            <div style="margin-top: 25px;">
              <button class="has-font-3" style="width: 110px;" phx-click="open-mobile-header">
                <img src="/svg/yellow-ellipse.svg" />
                <div class="has-font-3" style="position: relative; bottom: 53px; font-size: 30px;">
                  menu
                </div>
              </button>
            </div>
          </div>
        </div>
      </nav>
      <nav
        :if={@open}
        class="is-navbar-mobile-open"
        style="background: #F8FC5F; position: fixed; top: 0; left: 0; bottom: 0; right: 0;"
      >
        <div style="display: flex; justify-content: center; padding-top: 100px; padding-bottom: 250px;">
          <div style="display: flex; flex-direction: column; align-items: center;">
            <div>
              <%= render_slot(@landing) %>
            </div>
            <div style="margin-top: 100px;">
              <%= render_slot(@checkout) %>
            </div>
            <div style="margin-top: 100px;">
              <%= render_slot(@my_account) %>
            </div>
          </div>
        </div>
      </nav>
    </div>
    """
  end

  defp checkout_href(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/checkout">
      carrinho
    </.link>
    """
  end

  defp login_href(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/users/log_in">
      log in
    </.link>
    """
  end

  defp my_store_href(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/my-store">
      minha loja
    </.link>
    """
  end

  defp no_store_yet_href(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/upload">
      quero vender
    </.link>
    """
  end

  defp no_store_yet_href_selected(assigns) do
    ~H"""
    <div>
      quero vender
    </div>
    """
  end

  defp my_account_href(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/my-account">
      conta
    </.link>
    """
  end

  defp landing_href_selected_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/">
      <div class="has-font-3" style="font-size: 32px; text-decoration: underline;">
        plazaaaaa
      </div>
    </.link>
    """
  end

  defp landing_href_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/">
      <div class="has-font-3" style="font-size: 32px; text-decoration: underline;">
        plazaaaaa
      </div>
    </.link>
    """
  end

  defp login_href_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/users/log_in">
      <div class="has-font-3" style="font-size: 32px; text-decoration: underline;">
        log in
      </div>
    </.link>
    """
  end

  defp login_href_selected_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/users/log_in">
      <div class="has-font-3" style="font-size: 32px; text-decoration: underline;">
        log in
      </div>
    </.link>
    """
  end

  defp checkout_href_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/checkout">
      <div class="has-font-3" style="font-size: 32px; text-decoration: underline;">
        carrinho
      </div>
    </.link>
    """
  end

  defp checkout_href_selected_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/checkout">
      <div class="has-font-3" style="font-size: 32px; text-decoration: underline;">
        carrinho
      </div>
    </.link>
    """
  end

  defp no_store_yet_href_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/upload">
      <div class="has-font-3" style="font-size: 32px; text-decoration: underline;">
        quero vender
      </div>
    </.link>
    """
  end

  defp no_store_yet_href_selected_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/upload">
      <div class="has-font-3" style="font-size: 32px; text-decoration: underline;">
        quero vender
      </div>
    </.link>
    """
  end

  defp my_account_href_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/my-account">
      <div class="has-font-3" style="font-size: 32px; text-decoration: underline;">
        minha conta
      </div>
    </.link>
    """
  end

  defp my_account_href_selected_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/my-account">
      <div class="has-font-3" style="font-size: 32px; text-decoration: underline;">
        minha conta
      </div>
    </.link>
    """
  end
end
