defmodule PlazaWeb.LandingLive do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias Plaza.Products
  alias PlazaWeb.ProductComponent

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    products = Products.top_4_paginated(%{before: nil, after: nil})
    IO.inspect(products)

    seller =
      case socket.assigns.current_user do
        nil ->
          nil

        %{id: id} ->
          Accounts.get_seller_by_id(id)
      end

    socket =
      socket
      |> assign(products: products.entries)
      |> assign(cursor_before: nil)
      |> assign(cursor_after: products.metadata.after)
      |> assign(page_title: "Hello Plaza")
      |> assign(header: :landing)
      |> assign(seller: seller)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("product-href", %{"product-id" => product_id}, socket) do
    params = %{"product-id" => product_id}
    url = URI.encode_query(params)
    {:noreply, push_navigate(socket, to: "/product?#{url}")}
  end

  def handle_event("cursor-after", _, socket) do
    products = Products.top_4_paginated(%{before: nil, after: socket.assigns.cursor_after})
    IO.inspect(products)

    socket =
      socket
      |> assign(products: products.entries)
      |> assign(cursor_before: products.metadata.before)
      |> assign(cursor_after: products.metadata.after)

    {:noreply, socket}
  end

  def handle_event("cursor-before", _, socket) do
    products = Products.top_4_paginated(%{before: socket.assigns.cursor_before, after: nil})
    IO.inspect(products)

    socket =
      socket
      |> assign(products: products.entries)
      |> assign(cursor_before: products.metadata.before)
      |> assign(cursor_after: products.metadata.after)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="mt-large mx-large">
      <div class="is-size-1-desktop is-size-2-touch mb-medium mt-large">onde artistas vestem</div>
      <div class="is-size-3-desktop is-size-4-touch">
        <div class="mb-small">produtos em alta</div>
      </div>
      <div>
        <ProductComponent.products4 products={@products}></ProductComponent.products4>
        <div style="display: flex; justify-content: space-around;">
          <div>
            <button :if={@cursor_before} phx-click="cursor-before">
              here
            </button>
          </div>
          <div>
            <button :if={@cursor_after} phx-click="cursor-after">
              and here
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
