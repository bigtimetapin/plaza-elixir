defmodule PlazaWeb.ProductLive do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias Plaza.Accounts.Seller
  alias Plaza.Products
  alias PlazaWeb.ProductComponent

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket =
      if connected?(socket) do
        socket
      else
        socket
        |> assign(product: nil)
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
      else
        socket
      end

    IO.inspect(socket.assigns)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(%{product: nil} = assigns) do
    ~H"""
    <div class="mx-large">
      <div>
        product does not exist
      </div>
    </div>
    """
  end

  def render(%{product: product} = assigns) do
    ~H"""
    <div class="mx-large">
      <div>
        <ProductComponent.product product={product} />
      </div>
    </div>
    """
  end
end
