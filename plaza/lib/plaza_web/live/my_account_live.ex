defmodule PlazaWeb.MyAccountLive do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias Plaza.Accounts.Seller

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    seller = Accounts.get_seller_by_id(socket.assigns.current_user.id)
    IO.inspect(seller)

    socket =
      socket
      |> assign(:header, :my_account)
      |> assign(:seller, seller)
      |> assign(:user_name_form, nil)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("open-mobile-header", _, socket) do
    socket =
      socket
      |> assign(mobile_header_open: true)

    {:noreply, socket}
  end

  def handle_event("close-mobile-header", _, socket) do
    socket =
      socket
      |> assign(mobile_header_open: false)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="is-my-account-page-desktop">
      <div
        class="has-font-3"
        style="display: flex; margin-top: 200px; margin-bottom: 250px; margin-left: 100px; margin-right: 10px;"
      >
        <div style="margin-right: 50px;">
          <img src="/svg/big-yellow-circle.svg" style="width: 350px;" />
        </div>
        <div style="margin-top: 30px;">
          <h2 style="font-size: 32px; margin-bottom: 50px;">
            Minha Conta
          </h2>
          <div style="font-size: 24px;">
            email cadastrado:
          </div>
          <div style="font-size: 24px; margin-bottom: 50px;">
            <%= @current_user.email %>
          </div>
          <div style="font-size: 24px; text-decoration: underline;">
            <.link href="/users/log_out" method="delete">
              Sair
            </.link>
          </div>
        </div>
      </div>
    </div>
    <div class="is-my-account-page-mobile">
      <div
        class="has-font-3"
        style="display: flex; justify-content: center; margin-top: 200px; margin-bottom: 250px; margin-left: 10px; margin-right: 10px;"
      >
        <div style="display: flex; flex-direction: column;">
          <img src="/svg/yellow-rectangle.svg" style="margin-bottom: 50px;" />
          <h2 style="font-size: 32px; margin-bottom: 50px;">
            Minha Conta
          </h2>
          <div style="font-size: 24px;">
            email cadastrado:
          </div>
          <div style="font-size: 24px; margin-bottom: 50px;">
            <%= @current_user.email %>
          </div>
          <div style="font-size: 24px; text-decoration: underline;">
            <.link href="/users/log_out" method="delete">
              Sair
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
