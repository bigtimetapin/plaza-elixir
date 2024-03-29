defmodule PlazaWeb.AdminLive do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias Plaza.Products
  alias PlazaWeb.ProductComponent

  @admin_list [
    "bigtimetapin@gmail.com",
    "alexander@plazaaaaa.com",
    "alexandrensmarin@gmail.com",
    "am.cauliflower.am@gmail.com"
  ]

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    is_admin = Enum.member?(@admin_list, socket.assigns.current_user.email)

    socket =
      socket
      |> assign(is_admin: is_admin)
      |> assign(
        search_form:
          to_form(%{
            "seller_user_name" => nil
          })
      )
      |> assign(sellers: [])
      |> assign(seller: nil)
      |> assign(seller_products: [])
      |> assign(num_seller_products: 0)

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

  def handle_event("change-search-form", %{"seller_user_name" => seller_user_name}, socket) do
    sellers = Accounts.get_sellers_by_user_name_that_contain(seller_user_name)

    socket =
      socket
      |> assign(sellers: sellers)

    {:noreply, socket}
  end

  def handle_event("submit-search-form", params, socket) do
    {:noreply, socket}
  end

  def handle_event("seller", %{"user-id" => user_id}, socket) do
    seller = Accounts.get_seller_by_id(user_id)
    seller_products = Products.list_active_products_by_user_id(user_id)
    num_seller_products = Enum.count(seller_products)

    socket =
      socket
      |> assign(seller: seller)
      |> assign(seller_products: seller_products)
      |> assign(num_seller_products: num_seller_products)

    {:noreply, socket}
  end

  def handle_event("curate", %{"product-id" => product_id}, socket) do
    product = Products.get_product!(product_id)
    {:ok, product} = Products.curate_product(product)
    seller_products = Products.list_active_products_by_user_id(socket.assigns.seller.user_id)

    socket =
      socket
      |> assign(seller_products: seller_products)

    {:noreply, socket}
  end

  def handle_event("un-curate", %{"product-id" => product_id}, socket) do
    product = Products.get_product!(product_id)
    {:ok, product} = Products.uncurate_product(product)
    seller_products = Products.list_active_products_by_user_id(socket.assigns.seller.user_id)

    socket =
      socket
      |> assign(seller_products: seller_products)

    {:noreply, socket}
  end

  def handle_event("top", %{"product-id" => product_id}, socket) do
    product = Products.get_product!(product_id)
    {:ok, product} = Products.top_product(product)
    seller_products = Products.list_active_products_by_user_id(socket.assigns.seller.user_id)

    socket =
      socket
      |> assign(seller_products: seller_products)

    {:noreply, socket}
  end

  def handle_event("un-top", %{"product-id" => product_id}, socket) do
    product = Products.get_product!(product_id)
    {:ok, product} = Products.untop_product(product)
    seller_products = Products.list_active_products_by_user_id(socket.assigns.seller.user_id)

    socket =
      socket
      |> assign(seller_products: seller_products)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(%{is_admin: true, seller: nil} = assigns) do
    ~H"""
    <div
      class="has-font-3"
      style="display: flex; justify-content: center; margin-top: 150px; margin-bottom: 200px;"
    >
      <div style="display: flex; flex-direction: column;">
        <div style="display: flex; justify-content: center; margin-bottom: 10px;">
          <div>
            <div style="font-size: 36px; text-align: center; margin-top: 25px; margin-bottom: 25px;">
              curate products by seller
            </div>
            <.form for={@search_form} phx-change="change-search-form" phx-submit="submit-search-form">
              <.input
                field={@search_form[:seller_user_name]}
                type="text"
                placeholder="seller-user-name"
                class="text-input-1"
                style="text-align: center; width: 500px;"
                phx-debounce="500"
              />
            </.form>
          </div>
        </div>
        <div style="display: flex; flex-direction: column; font-size: 32px;">
          <button :for={seller <- @sellers} phx-click="seller" phx-value-user-id={seller.user_id}>
            <%= seller.user_name %>
          </button>
        </div>
      </div>
    </div>
    """
  end

  def render(%{is_admin: true} = assigns) do
    ~H"""
    <div class="has-font-3" style="display: flex; justify-content: center; margin-top: 150px;">
      <div style="display: flex; flex-direction: column; font-size: 32px;">
        <div style="text-align: center;">
          <%= "seller selected: #{@seller.user_name}" %>
        </div>
        <div style="text-align: center; margin-bottom: 50px;">
          <%= "total number of products: #{@num_seller_products}" %>
        </div>
        <div
          :for={product <- @seller_products}
          style="display: flex; flex-direction: column; border: 1px dotted black; margin-bottom: 25px; padding: 50px; width: 600px;"
        >
          <ProductComponent.product product={product} meta={true} disabled={true} />
          <div>
            <%= "curated: #{product.curated}" %>
          </div>
          <div style="margin-bottom: 5px;">
            <%= "top: #{product.top}" %>
          </div>
          <div>
            <button :if={!product.curated} phx-click="curate" phx-value-product-id={product.id}>
              mark as curated
            </button>
            <button :if={product.curated} phx-click="un-curate" phx-value-product-id={product.id}>
              un-mark as curated
            </button>
          </div>
          <div>
            <button :if={!product.top} phx-click="top" phx-value-product-id={product.id}>
              mark as top
            </button>
            <button :if={product.top} phx-click="un-top" phx-value-product-id={product.id}>
              un-mark as top
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="has-font-3" style="display: flex; justify-content: center;">
      not authorized
    </div>
    """
  end
end
