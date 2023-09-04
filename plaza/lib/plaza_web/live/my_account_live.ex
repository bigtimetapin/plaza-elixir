defmodule PlazaWeb.MyAccountLive do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias Plaza.Accounts.Seller

  @site "https://plazaaaaa.fly.dev"

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    seller = Accounts.get_seller_by_id(socket.assigns.current_user.id)
    IO.inspect(seller)

    payouts_enabled =
      case seller do
        nil ->
          nil

        %Seller{stripe_id: stripe_id} ->
          case stripe_id do
            nil ->
              nil

            defined ->
              case Stripe.Account.retrieve(defined) do
                {:ok, %Stripe.Account{payouts_enabled: bool}} ->
                  bool

                _ ->
                  false
              end
          end
      end

    socket =
      socket
      |> assign(:header, :my_account)
      |> assign(:seller, seller)
      |> assign(:user_name_form, nil)
      |> assign(:payouts_enabled, payouts_enabled)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"stripe-setup-refresh" => stripe_id}, _uri, socket) do
    socket =
      case connected?(socket) do
        true ->
          {:ok, %Stripe.AccountLink{url: stripe_account_link_url}} =
            Stripe.AccountLink.create(%{
              account: stripe_id,
              refresh_url: "#{@site}/my-account?stripe-setup-refresh=#{stripe_id}",
              return_url: "#{@site}/my-account?stripe-setup-return=#{stripe_id}",
              type: :account_onboarding
            })

          IO.inspect(stripe_account_link_url)

          socket
          |> redirect(external: stripe_account_link_url)

        false ->
          socket
      end

    {:noreply, socket}
  end

  def handle_params(%{"stripe-setup-return" => stripe_id}, _uri, socket) do
    socket =
      case connected?(socket) do
        true ->
          IO.inspect(stripe_id)

          {:ok,
           %Stripe.Account{
             details_submitted: details_submitted,
             payouts_enabled: payouts_enabled
           } = stripe_account} = Stripe.Account.retrieve(stripe_id)

          IO.inspect(details_submitted)
          IO.inspect(payouts_enabled)

          seller = Accounts.get_seller_by_id(socket.assigns.current_user.id)

          IO.inspect(seller)

          seller =
            case details_submitted do
              true ->
                {:ok, seller} = Accounts.update_seller(seller, %{"stripe_id" => stripe_id})
                seller

              false ->
                seller
            end

          IO.inspect(seller)

          socket
          |> assign(:seller, seller)
          |> assign(:payouts_enabled, payouts_enabled)

        false ->
          socket
      end

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
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

  def handle_event("stripe-link-account", _params, socket) do
    {:ok, %Stripe.Account{id: stripe_id}} = Stripe.Account.create(%{type: :express})

    {:ok, %Stripe.AccountLink{url: stripe_account_link_url}} =
      Stripe.AccountLink.create(%{
        account: stripe_id,
        refresh_url: "#{@site}/my-account?stripe-setup-refresh=#{stripe_id}",
        return_url: "#{@site}/my-account?stripe-setup-return=#{stripe_id}",
        type: :account_onboarding
      })

    IO.inspect(stripe_account_link_url)

    socket =
      socket
      |> redirect(external: stripe_account_link_url)

    {:noreply, socket}
  end

  def handle_event("stripe-enable-payouts", %{"stripe-id" => stripe_id}, socket) do
    {:noreply, push_patch(socket, to: "/my-account?stripe-setup-refresh=#{stripe_id}")}
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
    </div>
    """
  end

  def render(%{seller: %Seller{stripe_id: nil}} = assigns) do
    ~H"""
    <div class="mt-large mx-large">
      <%= @seller.user_name %>
    </div>

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
end
