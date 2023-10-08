defmodule PlazaWeb.ProductLive do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias Plaza.Accounts.Seller
  alias Plaza.Dimona
  alias Plaza.Products
  alias PlazaWeb.ProductComponent

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket =
      if connected?(socket) do
        socket
      else
        socket
        |> assign(waiting: true)
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"user-name" => user_name, "product-name" => product_name}, _uri, socket) do
    socket =
      if connected?(socket) do
        seller = Accounts.get_seller_by_user_name(user_name)
        IO.inspect(seller)

        product =
          case seller do
            nil ->
              nil

            nnil ->
              Products.get_product(
                seller.user_id,
                product_name
              )
          end

        IO.inspect(product)

        socket
        |> assign(seller: seller)
        |> assign(product: product)
        |> assign(step: 1)
        |> assign(waiting: false)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("step", %{"step" => "2"}, socket) do
    socket =
      socket
      |> assign(step: 2)
      |> assign(cep: nil)

    {:noreply, socket}
  end

  def handle_event("change-cep-input", %{"cep" => cep}, socket) do
    cep =
      case cep do
        "" ->
          nil

        nes ->
          nes
      end

    socket =
      socket
      |> assign(cep: cep)

    {:noreply, socket}
  end

  def handle_event("submit-cep-input", _params, socket) do
    params = %{"zipcode" => socket.assigns.cep}
    result = Dimona.Requests.Shipping.post(params)
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(%{waiting: true} = assigns) do
    ~H"""
    <div style="margin-top: 150px;">
      <div style="display: flex; justify-content: center;">
        waiting
      </div>
    </div>
    """
  end

  def render(%{product: nil} = assigns) do
    ~H"""
    <div>
      <div style="display: flex; justify-content: center;">
        product does not exist
      </div>
    </div>
    """
  end

  def render(%{product: product, step: 1} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px;">
      <div>
        <ProductComponent.product product={product} />
      </div>
      <div>
        <button phx-click="step" phx-value-step="2">
          purchase
        </button>
      </div>
    </div>
    """
  end

  def render(%{product: product, step: 2} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px;">
      <div>
        <ProductComponent.product product={product} />
      </div>
      <div>
        <div>
          we need your cep to figure out shipping costs
        </div>
        <div>
          <form>
            <.input
              type="text"
              name="cep"
              value={@cep}
              placeholder="cep"
              class="text-input-1"
              phx-change="change-cep-input"
            >
            </.input>
          </form>
        </div>
        <div>
          <button disabled={!@cep} phx-click="submit-cep-input" style={if !@cep, do: "opacity: 50%;"}>
            submit
          </button>
        </div>
      </div>
    </div>
    """
  end
end
