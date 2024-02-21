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
    top_products = GenServer.call(TopProducts, :get)
    IO.inspect(top_products)
    first = Products.get_product(top_products.first)
    second = Products.get_product(top_products.second)
    third = Products.get_product(top_products.third)

    socket =
      socket
      |> assign(is_admin: is_admin)
      |> assign(
        search_form:
          to_form(%{
            "seller_user_name" => nil
          })
      )
      |> assign(
        top_products_form:
          to_form(%{
            "first" => top_products.first,
            "second" => top_products.second,
            "third" => top_products.third
          })
      )
      |> assign(sellers: [])
      |> assign(seller: nil)
      |> assign(seller_products: [])
      |> assign(num_seller_products: 0)
      |> assign(first: first)
      |> assign(second: second)
      |> assign(third: third)

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
    seller_products = Products.list_products_by_user_id(user_id)
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
    seller_products = Products.list_products_by_user_id(socket.assigns.seller.user_id)

    socket =
      socket
      |> assign(seller_products: seller_products)

    {:noreply, socket}
  end

  def handle_event("un-curate", %{"product-id" => product_id}, socket) do
    product = Products.get_product!(product_id)
    {:ok, product} = Products.uncurate_product(product)
    seller_products = Products.list_products_by_user_id(socket.assigns.seller.user_id)

    socket =
      socket
      |> assign(seller_products: seller_products)

    {:noreply, socket}
  end

  def handle_event("change-top-products-form-first", %{"first" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("change-top-products-form-first", %{"first" => product_id}, socket) do
    first = Products.get_product(product_id)

    socket =
      socket
      |> assign(first: first)

    {:noreply, socket}
  end

  def handle_event("change-top-products-form-second", %{"second" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("change-top-products-form-second", %{"second" => product_id}, socket) do
    second = Products.get_product(product_id)

    socket =
      socket
      |> assign(second: second)

    {:noreply, socket}
  end

  def handle_event("change-top-products-form-third", %{"third" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("change-top-products-form-third", %{"third" => product_id}, socket) do
    third = Products.get_product(product_id)

    socket =
      socket
      |> assign(third: third)

    {:noreply, socket}
  end

  def handle_event("submit-top-products-form", _, socket) do
    first = socket.assigns.first.id
    second = socket.assigns.second.id
    third = socket.assigns.third.id
    state = %{first: first, second: second, third: third}
    GenServer.cast(TopProducts, {:set, state})
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
        <div style="margin-bottom: 200px;">
          <.form
            for={@top_products_form}
            style="border: 1px dotted grey;"
            phx-submit="submit-top-products-form"
          >
            <div style="font-size: 36px; text-align: center; margin-top: 25px;">
              top 3 products
            </div>
            <div style="display: flex; margin-top: 25px;">
              <div style="width: 400px; margin-left: 50px; margin-right: 50px; border: 1px double grey;">
                <.input
                  field={@top_products_form[:first]}
                  type="text"
                  placeholder="first"
                  style="width: 150px; margin: 10px;"
                  phx-debounce="500"
                  phx-change="change-top-products-form-first"
                />
                <div style="margin: 10px;">
                  <ProductComponent.product product={@first} meta={false} disabled={true} />
                </div>
              </div>
              <div style="width: 400px; margin-right: 50px; border: 1px double grey;">
                <.input
                  field={@top_products_form[:second]}
                  type="text"
                  placeholder="second"
                  style="width: 150px; margin: 10px;"
                  phx-debounce="500"
                  phx-change="change-top-products-form-second"
                />
                <div style="margin: 10px;">
                  <ProductComponent.product product={@second} meta={false} disabled={true} />
                </div>
              </div>
              <div style="width: 400px; margin-right: 50px; border: 1px double grey;">
                <.input
                  field={@top_products_form[:third]}
                  type="text"
                  placeholder="third"
                  style="width: 150px; margin: 10px;"
                  phx-debounce="500"
                  phx-change="change-top-products-form-third"
                />
                <div style="margin: 10px;">
                  <ProductComponent.product product={@third} meta={false} disabled={true} />
                </div>
              </div>
            </div>
            <div style="display: flex; justify-content: center; margin-top: 50px; margin-bottom: 50px;">
              <button
                class="has-font-3"
                style="width: 500px; font-size: 28px; border: 1px dotted grey;"
              >
                submit
              </button>
            </div>
          </.form>
        </div>
        <div style="border-top: 1px solid grey; display: flex; justify-content: center;">
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
        <div style="display: flex; flex-direction: column;">
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
      <div style="display: flex; flex-direction: column;">
        <div style="text-align: center;">
          <%= "seller selected; #{@seller.user_name}" %>
        </div>
        <div style="text-align: center; margin-bottom: 50px;">
          <%= "total number of products; #{@num_seller_products}" %>
        </div>
        <div
          :for={product <- @seller_products}
          style="display: flex; flex-direction: column; border: 1px dotted black; margin-bottom: 25px; padding: 50px;"
        >
          <ProductComponent.product product={product} meta={true} disabled={true} />
          <div style="text-align: center;">
            <%= "product curated; #{product.curated}" %>
          </div>
          <button :if={!product.curated} phx-click="curate" phx-value-product-id={product.id}>
            mark as curated
          </button>
          <button :if={product.curated} phx-click="un-curate" phx-value-product-id={product.id}>
            un-mark as curated
          </button>
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
