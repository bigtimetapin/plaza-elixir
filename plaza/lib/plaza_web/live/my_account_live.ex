defmodule PlazaWeb.MyAccountLive do
  use PlazaWeb, :live_view

  alias Plaza.Accounts

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    IO.inspect(socket)

    seller = Accounts.get_seller_by_id(socket.assigns.current_user.id)

    IO.inspect(seller)

    socket =
      socket
      |> assign(:header, :my_account)
      |> assign(:seller, seller)
      |> assign(:user_name, nil)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("user-name-change", %{"user-name" => str}, socket) do
    socket =
      socket
      |> assign(user_name: str)

    {:noreply, socket}
  end

  def handle_event("user-name-submit", %{"user-name" => str}, socket) do
    # response = Accounts.create_seller(%{user_id: socket.assigns.current_user.id, user_name: str})
    # IO.inspect(response)
    # seller = Accounts.get_seller_by_id(socket.assigns.current_user.id)
    # IO.inspect(seller)

    {:ok, %Stripe.Account{id: id}} = Stripe.Account.create(%{type: :express})
    IO.inspect(id)

    response =
      Stripe.AccountLink.create(%{
        account: id,
        refresh_url: "http://localhost:4000/my-account",
        return_url: "http://localhost:4000/my-account",
        type: :account_onboarding
      })

    IO.inspect(response)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(%{seller: nil} = assigns) do
    ~H"""
    <div class="mt-large mx-large">
      <div>
        create user-name
        <form phx-change="user-name-change" phx-submit="user-name-submit">
          <input type="text" name="user-name" value={@user_name} />
          <button type="submit">submit</button>
        </form>
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
        create user-name
        <form phx-change="user-name-change" phx-submit="user-name-submit">
          <input type="text" name="user-name" value={@user_name} />
          <button type="submit">submit</button>
        </form>
      </div>
    </div>
    """
  end
end
