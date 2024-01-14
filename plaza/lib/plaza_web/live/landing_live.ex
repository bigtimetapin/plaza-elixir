defmodule PlazaWeb.LandingLive do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias Plaza.Products
  alias PlazaWeb.ProductComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    IO.inspect(socket.assigns.current_user)
    ## curated products 
    curated_products = Products.top_4_paginated(%{before: nil, after: nil})
    ## uncurated products
    uncurated_products = Products.top_8_uncurated_paginated(%{before: nil, after: nil})
    ## split first 4 and second 4 uncurated products
    first_4_uncurated_products = Enum.slice(uncurated_products.entries, 0, 4)
    second_4_uncurated_products = Enum.slice(uncurated_products.entries, 4, 4)
    ## split first, last, and middle uncurated products 
    {first_uncurated_product, last_uncurated_product, middle_uncurated_products} =
      split_uncurated_products(uncurated_products.entries)

    seller =
      case socket.assigns.current_user do
        nil ->
          nil

        %{id: id} ->
          Accounts.get_seller_by_id(id)
      end

    socket =
      socket
      |> assign(curated_products: curated_products.entries)
      |> assign(curated_cursor_before: nil)
      |> assign(curated_cursor_after: curated_products.metadata.after)
      |> assign(first_4_uncurated_products: first_4_uncurated_products)
      |> assign(second_4_uncurated_products: second_4_uncurated_products)
      |> assign(first_uncurated_product: first_uncurated_product)
      |> assign(last_uncurated_product: last_uncurated_product)
      |> assign(middle_uncurated_products: middle_uncurated_products)
      |> assign(uncurated_cursor_before: nil)
      |> assign(uncurated_cursor_after: uncurated_products.metadata.after)
      |> assign(page_title: "Hello Plaza")
      |> assign(header: :landing)
      |> assign(seller: seller)

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

  def handle_event("product-href", %{"product-id" => product_id}, socket) do
    params = %{"product-id" => product_id}
    url = URI.encode_query(params)
    {:noreply, push_navigate(socket, to: "/product?#{url}")}
  end

  def handle_event("curated-cursor-after", _, socket) do
    curated_products =
      Products.top_4_paginated(%{before: nil, after: socket.assigns.curated_cursor_after})

    socket =
      socket
      |> assign(curated_products: curated_products.entries)
      |> assign(curated_cursor_before: curated_products.metadata.before)
      |> assign(curated_cursor_after: curated_products.metadata.after)

    {:noreply, socket}
  end

  def handle_event("curated-cursor-before", _, socket) do
    curated_products =
      Products.top_4_paginated(%{before: socket.assigns.curated_cursor_before, after: nil})

    socket =
      socket
      |> assign(curated_products: curated_products.entries)
      |> assign(curated_cursor_before: curated_products.metadata.before)
      |> assign(curated_cursor_after: curated_products.metadata.after)

    {:noreply, socket}
  end

  def handle_event("uncurated-cursor-after", _, socket) do
    uncurated_products =
      Products.top_8_uncurated_paginated(%{
        before: nil,
        after: socket.assigns.uncurated_cursor_after
      })

    first_4_uncurated_products = Enum.slice(uncurated_products.entries, 0, 4)
    second_4_uncurated_products = Enum.slice(uncurated_products.entries, 4, 4)

    ## split first, last, and middle uncurated products 
    {first_uncurated_product, last_uncurated_product, middle_uncurated_products} =
      split_uncurated_products(uncurated_products.entries)

    socket =
      socket
      |> assign(first_4_uncurated_products: first_4_uncurated_products)
      |> assign(second_4_uncurated_products: second_4_uncurated_products)
      |> assign(first_uncurated_product: first_uncurated_product)
      |> assign(last_uncurated_product: last_uncurated_product)
      |> assign(middle_uncurated_products: middle_uncurated_products)
      |> assign(uncurated_cursor_before: uncurated_products.metadata.before)
      |> assign(uncurated_cursor_after: uncurated_products.metadata.after)

    {:noreply, socket}
  end

  def handle_event("uncurated-cursor-before", _, socket) do
    uncurated_products =
      Products.top_8_uncurated_paginated(%{
        before: socket.assigns.uncurated_cursor_before,
        after: nil
      })

    first_4_uncurated_products = Enum.slice(uncurated_products.entries, 0, 4)
    second_4_uncurated_products = Enum.slice(uncurated_products.entries, 4, 4)
    ## split first, last, and middle uncurated products 
    {first_uncurated_product, last_uncurated_product, middle_uncurated_products} =
      split_uncurated_products(uncurated_products.entries)

    socket =
      socket
      |> assign(first_4_uncurated_products: first_4_uncurated_products)
      |> assign(second_4_uncurated_products: second_4_uncurated_products)
      |> assign(first_uncurated_product: first_uncurated_product)
      |> assign(last_uncurated_product: last_uncurated_product)
      |> assign(middle_uncurated_products: middle_uncurated_products)
      |> assign(uncurated_cursor_before: uncurated_products.metadata.before)
      |> assign(uncurated_cursor_after: uncurated_products.metadata.after)

    {:noreply, socket}
  end

  defp split_uncurated_products(uncurated_products) do
    ## split first, last, and middle uncurated products 
    case Enum.count(uncurated_products) do
      0 ->
        {nil, nil, []}

      1 ->
        {List.first(uncurated_products), nil, []}

      2 ->
        {List.first(uncurated_products), List.last(uncurated_products), []}

      _ ->
        middle = uncurated_products |> Enum.drop(1) |> Enum.drop(-1)

        {List.first(uncurated_products), List.last(uncurated_products), middle}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="is-landing-desktop mt-large mx-large">
      <div>
        <ProductComponent.products4 products={@curated_products} />
        <div style="display: flex; justify-content: space-around;">
          <div>
            <button :if={@curated_cursor_before} phx-click="curated-cursor-before">
              prev
            </button>
          </div>
          <div>
            <button :if={@curated_cursor_after} phx-click="curated-cursor-after">
              next
            </button>
          </div>
        </div>
      </div>
      <div style="display: flex; margin-top: 100px; margin-bottom: 100px;">
        <div class="has-font-3">
          <h2 style="font-size: 63px; margin-bottom: 25px;">
            plazaaaaa é um espaço público para venda de camisetas
          </h2>
          <h3 style="font-size: 38px; min-width: 300px; max-width: 1005px; line-height: 45px; margin-bottom: 25px;">
            qualquer um pode publicar seus designs e vender por aqui, basta escolher sua margem de lucro e subir a arte, o resto a gente cuida.
          </h3>
          <h3 style="font-size: 38px; min-width: 300px; max-width: 970px; line-height: 45px; margin-bottom: 25px;">
            cada produto vendido é produzido sob demanda e chega na casa do cliente final em até 7 dias úteis.
          </h3>
          <h3 style="font-size: 38px; min-width: 300px; max-width: 970px; line-height: 45px; margin-bottom: 25px;">
            produzimos sob demanda e não tem desperdício.
            <.link navigate="/upload" style="text-decoration: underline; margin-left: 50px;">
              quero vender
            </.link>
          </h3>
        </div>
        <div style="min-width: 250px;">
          <img src="svg/star.svg" />
        </div>
      </div>
      <div>
        <div style="margin-bottom: 100px;">
          <ProductComponent.products4 products={@first_4_uncurated_products} />
        </div>
        <div>
          <ProductComponent.products4 products={@second_4_uncurated_products} />
        </div>
        <div style="display: flex; justify-content: space-around; margin-top: 25px; margin-bottom: 50px;">
          <div>
            <button :if={@uncurated_cursor_before} phx-click="uncurated-cursor-before">
              prev
            </button>
          </div>
          <div>
            <button :if={@uncurated_cursor_after} phx-click="uncurated-cursor-after">
              next
            </button>
          </div>
        </div>
        <div style="min-width: 300px; max-width: 1650px; height: 495px; border: 1px solid gray; margin-bottom: 1000px;" />
      </div>
    </div>
    <div
      class="is-landing-mobile has-font-3"
      phx-hook="LandingInfiniteScroll"
      id="landing-scroll-container"
    >
      <div style="display: flex; justify-content: center;">
        <div style="display: flex; flex-direction: column; text-align: center; width: 400px;">
          <h1 style="font-size: 54px; margin-bottom: 100px;">
            plazaaaaa
          </h1>
          <div :for={product <- @curated_products} style="margin-bottom: 150px; padding-right: 20px;">
            <ProductComponent.product product={product} meta={true} disabled={false} />
          </div>
          <div
            :if={@curated_products != []}
            style="display: flex; justify-content: space-around; margin-bottom: 500px;"
          >
            <div>
              <button :if={@curated_cursor_before} phx-click="curated-cursor-before">
                prev
              </button>
            </div>
            <div>
              <button :if={@curated_cursor_after} phx-click="curated-cursor-after">
                next
              </button>
            </div>
          </div>
          <div style="display: flex; margin-left: auto; margin-right: 20px; font-size: 22px;">
            em alta esta semana
          </div>
          <div style="display: flex; overflow-x: scroll;" id="landing-scroll">
            <div
              :if={@first_uncurated_product}
              style="margin-right: 25px;"
              id={if @uncurated_cursor_before, do: "landing-scroll-first"}
            >
              <ProductComponent.product
                product={@first_uncurated_product}
                meta={true}
                disabled={false}
              />
            </div>
            <div :for={product <- @middle_uncurated_products} style="margin-right: 25px;">
              <ProductComponent.product product={product} meta={true} disabled={false} />
            </div>
            <div
              :if={@last_uncurated_product}
              id={if @uncurated_cursor_after, do: "landing-scroll-last"}
            >
              <ProductComponent.product
                product={@last_uncurated_product}
                meta={true}
                disabled={false}
              />
            </div>
          </div>
          <h2 style="font-size: 50px; margin-bottom: 50px;">
            plazaaaaa é uma loja aberta para vender camisetas estampadas
          </h2>
          <div style="display: flex; justify-content: center; margin-bottom: 50px;">
            <img src="svg/star.svg" />
          </div>
          <h3 style="font-size: 28px; line-height: 35px; margin-bottom: 25px; margin-left: 2px; margin-right: 2px;">
            qualquer um pode publicar seus designs e vender por aqui, basta escolher sua margem de lucro e subir a arte, o resto a gente cuida.
          </h3>
          <h3 style="font-size: 28px; line-height: 35px; margin-bottom: 25px; margin-left: 2px; margin-right: 2px;">
            cada produto vendido é produzido sob demanda e chega na casa do cliente final em até 7 dias úteis.
          </h3>
          <h3 style="font-size: 28px; line-height: 35px; margin-bottom: 25px; margin-left: 2px; margin-right: 2px;">
            produzimos sob demanda e não tem desperdício, você recebe seus lucros e basicamente é isso, bem simples e facil como tudo deveria ser.
          </h3>
          <div style="margin-bottom: 250px;">
            <.link navigate="/upload" style="text-decoration: underline; font-size: 28px;">
              quero vender
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
