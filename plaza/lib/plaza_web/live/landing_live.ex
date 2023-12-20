defmodule PlazaWeb.LandingLive do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias Plaza.Products
  alias PlazaWeb.ProductComponent

  def mount(_params, session, socket) do
    products = Products.top_4_paginated()
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
      |> assign(page_title: "Hello Plaza")
      |> assign(header: :landing)
      |> assign(seller: seller)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="mt-large mx-large">
      <div class="is-size-1-desktop is-size-2-touch mb-medium mt-large">onde artistas vestem</div>
      <div class="is-size-3-desktop is-size-4-touch">
        <div class="mb-small">produtos em alta</div>
      </div>
      <ProductComponent.products4 products={@products}></ProductComponent.products4>
    </div>
    """
  end
end
