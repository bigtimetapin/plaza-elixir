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
          <div class="level-item pr-xmedium">
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
            <div style="position: absolute;">
              <div style="position: relative; left: 35px;">
                <img src="/svg/yellow-circle.svg" />
              </div>
            </div>
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
    <.left_desktop selected={true}>
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
    </.left_desktop>
    """
  end

  slot :login, required: true
  slot :store, required: true

  defp checkout_desktop(assigns) do
    ~H"""
    <.left_desktop selected={false}>
      <:right>
        <div class="level-item pr-xmedium">
          <%= render_slot(@login) %>
        </div>
        <div class="level-item pr-xmedium">
          <.link phx-click="close-mobile-header" navigate="/checkout">
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
    </.left_desktop>
    """
  end

  slot :store, required: true

  defp my_account_desktop(assigns) do
    ~H"""
    <.left_desktop>
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
        <div class="level-item pr-xmedium">
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
    </.left_desktop>
    """
  end

  attr :selected, :boolean, default: false
  attr :header, :atom, required: true
  slot :right, required: true

  defp left_desktop(assigns) do
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
    </div>
    """
  end

  defp mobile(assigns) do
    ~H"""
    <div>
      <nav :if={!@open} class="is-navbar-mobile-closed">
        <div style="display: flex; justify-content: center;">
          <div style="display: flex; flex-direction: column; align-items: center;">
            <div class="has-font-3" style="font-size: 60px; margin-bottom: 29px;">plazaaaaa</div>
            <button class="has-font-3" style="width: 110px;" phx-click="open-mobile-header">
              <img src="/svg/yellow-ellipse.svg" />
              <div class="has-font-3" style="position: relative; bottom: 53px; font-size: 30px;">
                menu
              </div>
            </button>
          </div>
        </div>
      </nav>
      <nav :if={@open} class="is-navbar-mobile-open">
        <div style="display: flex; justify-content: center; padding-top: 100px; padding-bottom: 250px;">
          <div style="display: flex; flex-direction: column; align-items: center;">
            <div class="has-font-3" style="font-size: 60px;">plazaaaaa</div>
            <div style="margin-top: 100px;">
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
    <.link phx-click="close-mobile-header" navigate="/my-account">
      conta
    </.link>
    """
  end

  defp landing_href_selected_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/">
      <div style="display: flex; align-items: center;">
        <div class="has-font-3" style="font-size: 32px;">
          loja
        </div>
        <div style="margin-left: 10px;">
          <img src="/svg/yellow-circle.svg" />
        </div>
      </div>
    </.link>
    """
  end

  defp landing_href_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/">
      <div class="has-font-3" style="font-size: 32px;">
        loja
      </div>
    </.link>
    """
  end

  defp login_href_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/users/log_in">
      <div class="has-font-3" style="font-size: 32px;">
        log in
      </div>
    </.link>
    """
  end

  defp login_href_selected_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/users/log_in">
      <div style="display: flex; align-items: center;">
        <div class="has-font-3" style="font-size: 32px;">
          log in
        </div>
        <div style="margin-left: 10px;">
          <img src="/svg/yellow-circle.svg" />
        </div>
      </div>
    </.link>
    """
  end

  defp checkout_href_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/checkout">
      <div class="has-font-3" style="font-size: 32px;">
        carrinho
      </div>
    </.link>
    """
  end

  defp checkout_href_selected_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/checkout">
      <div style="display: flex; align-items: center;">
        <div class="has-font-3" style="font-size: 32px;">
          carrinho
        </div>
        <div style="margin-left: 10px;">
          <img src="/svg/yellow-circle.svg" />
        </div>
      </div>
    </.link>
    """
  end

  defp no_store_yet_href_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/upload">
      <div class="has-font-3" style="font-size: 32px;">
        quero vender
      </div>
    </.link>
    """
  end

  defp no_store_yet_href_selected_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/upload">
      <div style="display: flex; align-items: center;">
        <div class="has-font-3" style="font-size: 32px;">
          quero vender
        </div>
        <div style="margin-left: 10px;">
          <img src="/svg/yellow-circle.svg" />
        </div>
      </div>
    </.link>
    """
  end

  defp my_account_href_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/my-account">
      <div class="has-font-3" style="font-size: 32px;">
        conta
      </div>
    </.link>
    """
  end

  defp my_account_href_selected_mobile(assigns) do
    ~H"""
    <.link phx-click="close-mobile-header" navigate="/my-account">
      <div style="display: flex; align-items: center;">
        <div class="has-font-3" style="font-size: 32px;">
          conta
        </div>
        <div style="margin-left: 10px;">
          <img src="/svg/yellow-circle.svg" />
        </div>
      </div>
    </.link>
    """
  end
end
