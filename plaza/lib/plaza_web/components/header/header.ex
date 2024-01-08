defmodule PlazaWeb.Header do
  use Phoenix.LiveComponent

  def update(%{header: header, current_user: current_user, seller: seller}, socket) do
    header =
      case header do
        nil -> :landing
        _ -> header
      end

    socket =
      socket
      |> assign(header: header)
      |> assign(current_user: current_user)
      |> assign(seller: seller)
      |> assign(mobile_open: false)

    {:ok, socket}
  end

  def handle_event("open-header", _, socket) do
    socket =
      socket
      |> assign(mobile_open: true)

    {:noreply, socket}
  end

  def handle_event("close-header", _, socket) do
    socket =
      socket
      |> assign(mobile_open: false)

    {:noreply, socket}
  end

  def render(%{header: :landing, current_user: nil} = assigns) do
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
        <:my_store>
          <.no_store_yet_href_mobile />
        </:my_store>
      </.mobile>
    </div>
    """
  end

  def render(%{header: :landing, seller: nil} = assigns) do
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
        <:my_store>
          <.no_store_yet_href_mobile />
        </:my_store>
      </.mobile>
    </div>
    """
  end

  def render(%{header: :landing} = assigns) do
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
        <:my_store>
          <.my_store_href_mobile />
        </:my_store>
      </.mobile>
    </div>
    """
  end

  def render(%{header: :login} = assigns) do
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
          <div class="level-item">
            <.no_store_yet_href />
          </div>
        </:right>
      </.left_desktop>
      <.mobile open={@mobile_open}>
        <:landing></:landing>
        <:my_account></:my_account>
        <:checkout></:checkout>
        <:my_store></:my_store>
      </.mobile>
    </div>
    """
  end

  def render(%{header: :my_store, current_user: nil, seller: nil} = assigns) do
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
        <:landing></:landing>
        <:my_account></:my_account>
        <:checkout></:checkout>
        <:my_store></:my_store>
      </.mobile>
    </div>
    """
  end

  def render(%{header: :my_store, seller: nil} = assigns) do
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
        <:landing></:landing>
        <:my_account></:my_account>
        <:checkout></:checkout>
        <:my_store></:my_store>
      </.mobile>
    </div>
    """
  end

  def render(%{header: :my_store} = assigns) do
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
        <:landing></:landing>
        <:my_account></:my_account>
        <:checkout></:checkout>
        <:my_store></:my_store>
      </.mobile>
    </div>
    """
  end

  def render(%{header: :my_account, seller: nil} = assigns) do
    ~H"""
    <div>
      <.my_account_desktop>
        <:store>
          <.no_store_yet_href />
        </:store>
      </.my_account_desktop>
      <.mobile open={@mobile_open}>
        <:landing></:landing>
        <:my_account></:my_account>
        <:checkout></:checkout>
        <:my_store></:my_store>
      </.mobile>
    </div>
    """
  end

  def render(%{header: :my_account} = assigns) do
    ~H"""
    <div>
      <.my_account_desktop>
        <:store>
          <.my_store_href />
        </:store>
      </.my_account_desktop>
      <.mobile open={@mobile_open}>
        <:landing></:landing>
        <:my_account></:my_account>
        <:checkout></:checkout>
        <:my_store></:my_store>
      </.mobile>
    </div>
    """
  end

  def render(%{header: :checkout, current_user: nil} = assigns) do
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
        <:landing></:landing>
        <:my_account></:my_account>
        <:checkout></:checkout>
        <:my_store></:my_store>
      </.mobile>
    </div>
    """
  end

  def render(%{header: :checkout, seller: nil} = assigns) do
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
        <:landing></:landing>
        <:my_account></:my_account>
        <:checkout></:checkout>
        <:my_store></:my_store>
      </.mobile>
    </div>
    """
  end

  def render(%{header: :checkout} = assigns) do
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
        <:landing></:landing>
        <:my_account></:my_account>
        <:checkout></:checkout>
        <:my_store></:my_store>
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
    <div id="mobile-header-target">
      <nav :if={!@open} class="is-navbar-mobile-closed" style="display: flex;">
        <div style="margin-left: auto; margin-right: 50px; display: flex; flex-direction: column; justify-content: center; height: 100px;">
          <button
            class="has-font-3"
            style="font-size: 32px;"
            phx-click="open-header"
            phx-target="#mobile-header-target"
          >
            open header
          </button>
        </div>
      </nav>
      <nav
        :if={@open}
        class="is-navbar-mobile-open"
        style="display: flex; justify-content: center; padding-top: 100px;"
      >
        <div style="display: flex; flex-direction: column; align-items: center;">
          <div style="font-size: 60px;">plazaaaaa</div>
          <div style="margin-top: 100px;">
            <%= render_slot(@landing) %>
          </div>
          <div style="margin-top: 100px;">
            <%= render_slot(@my_account) %>
          </div>
          <div style="margin-top: 100px;">
            <%= render_slot(@checkout) %>
          </div>
          <div style="margin-top: 100px;">
            <%= render_slot(@my_store) %>
          </div>
        </div>
      </nav>
    </div>
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
    <.link phx-target="#mobile-header-target" phx-click="close-header" navigate="/my-account">
      conta
    </.link>
    """
  end

  defp landing_href_selected_mobile(assigns) do
    ~H"""
    <.link phx-target="#mobile-header-target" phx-click="close-header" navigate="/">
      <div style="display: flex; align-items: center;">
        <div class="has-font-3" style="font-size: 40px;">
          loja
        </div>
        <div style="margin-left: 10px;">
          <img src="/svg/yellow-circle.svg" />
        </div>
      </div>
    </.link>
    """
  end

  defp login_href_mobile(assigns) do
    ~H"""
    <.link phx-target="#mobile-header-target" phx-click="close-header" navigate="/users/log_in">
      <div class="has-font-3" style="font-size: 40px;">
        log in
      </div>
    </.link>
    """
  end

  defp checkout_href_mobile(assigns) do
    ~H"""
    <.link phx-target="#mobile-header-target" phx-click="close-header" navigate="/checkout">
      <div class="has-font-3" style="font-size: 40px;">
        carrinho
      </div>
    </.link>
    """
  end

  defp no_store_yet_href_mobile(assigns) do
    ~H"""
    <.link phx-target="#mobile-header-target" phx-click="close-header" navigate="/upload">
      <div class="has-font-3" style="font-size: 40px;">
        quero vender
      </div>
    </.link>
    """
  end

  defp my_account_href_mobile(assigns) do
    ~H"""
    <.link phx-target="#mobile-header-target" phx-click="close-header" navigate="/my-account">
      <div class="has-font-3" style="font-size: 40px;">
        conta
      </div>
    </.link>
    """
  end

  defp my_store_href_mobile(assigns) do
    ~H"""
    <.link phx-target="#mobile-header-target" phx-click="close-header" navigate="/my-store">
      <div class="has-font-3" style="font-size: 40px;">
        minha loja
      </div>
    </.link>
    """
  end
end
