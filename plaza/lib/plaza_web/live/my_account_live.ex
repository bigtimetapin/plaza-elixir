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

  def handle_event("user-name-change", %{"user-name" => str}, socket) do
    socket =
      socket
      |> assign(user_name_form: str)

    {:noreply, socket}
  end

  def handle_event("user-name-submit", %{"user-name" => str}, socket) do
    attrs = %{
      user_id: socket.assigns.current_user.id,
      user_name: str
    }

    {:ok, seller} = Accounts.create_seller(attrs)
    IO.inspect(seller)

    socket =
      socket
      |> assign(:seller, seller)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(%{seller: nil} = assigns) do
    ~H"""
    <div class="mt-large mx-large">
      <div>
        create user-name
        <form phx-change="user-name-change" phx-submit="user-name-submit">
          <input type="text" name="user-name" value={@user_name_form} />
          <button type="submit">submit</button>
        </form>
      </div>

      <.logout />
    </div>
    """
  end

  def render(%{seller: %Seller{stripe_id: nil}} = assigns) do
    ~H"""
    <div class="mt-large mx-large">
      <%= @seller.user_name %>
    </div>

    <.logout />

    <div class="mt-large mx-large">
      <button phx-click="stripe-link-account">link stripe account</button>
    </div>
    """
  end

  def render(%{payouts_enabled: false} = assigns) do
    ~H"""
    <div class="mt-large mx-large">
      <%= @seller.user_name %>
    </div>

    <.logout />

    <div class="mt-large mx-large">
      <div>
        <%= "your seller stripe-id: #{@seller.stripe_id}" %>
      </div>
      <div>
        <button phx-click="stripe-enable-payouts" phx-value-stripe-id={@seller.stripe_id}>
          enable payouts
        </button>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="mt-large mx-large">
      <%= @seller.user_name %>
    </div>

    <div class="mt-large mx-large">
      <div>
        <%= "your seller stripe-id: #{@seller.stripe_id}" %>
      </div>
      <div>
        payouts enabled
      </div>
    </div>
    """
  end

  defp logout(assigns) do
    ~H"""
    <div>
      <.link href="/users/log_out" method="delete">
        log out
      </.link>
    </div>
    """
  end
end
