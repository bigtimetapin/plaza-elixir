defmodule PlazaWeb.LandingLive do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias Plaza.Products
  alias PlazaWeb.ProductComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
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

  @impl Phoenix.LiveView
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
      <div>
        <ProductComponent.products4 products={@products}></ProductComponent.products4>
        <div style="display: flex; justify-content: space-around;">
          <div>
            <button :if={@cursor_before} phx-click="cursor-before">
              prev
            </button>
          </div>
          <div>
            <button :if={@cursor_after} phx-click="cursor-after">
              next
            </button>
          </div>
        </div>
      </div>
      <div style="display: flex; margin-top: 100px;">
        <div class="has-font-3">
          <h2 style="font-size: 63px; margin-bottom: 25px;">
            plazaaaaa é um espaço público para venda de camisetas
          </h2>
          <h3 style="font-size: 38px; width: 1005px; line-height: 45px; margin-bottom: 25px;">
            qualquer um pode publicar seus designs e vender por aqui, basta escolher sua margem de lucro e subir a arte, o resto a gente cuida.
          </h3>
          <h3 style="font-size: 38px; width: 970px; line-height: 45px; margin-bottom: 25px;">
            cada produto vendido é produzido sob demanda e chega na casa do cliente final em até 7 dias úteis.
          </h3>
          <h3 style="font-size: 38px; width: 970px; line-height: 45px; margin-bottom: 25px;">
            produzimos sob demanda e não tem desperdício.
            <.link navigate="/upload" style="text-decoration: underline; margin-left: 50px;">
              quero vender
            </.link>
          </h3>
        </div>
        <div>
          <img src="svg/star.svg" />
        </div>
      </div>
    </div>
    """
  end
end
