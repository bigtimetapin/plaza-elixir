defmodule PlazaWeb.LandingLive do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias Plaza.Products
  alias PlazaWeb.ProductComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      case connected?(socket) do
        true ->
          ## top products
          top_product_ids = GenServer.call(TopProducts, :get)
          first = Products.get_product(top_product_ids.first)
          second = Products.get_product(top_product_ids.second)
          third = Products.get_product(top_product_ids.third)
          top_products = [first, second, third]
          ## curated products 
          curated_products =
            Products.top_n_paginated(
              %{
                before: nil,
                after: nil
              },
              3,
              true
            )

          ## uncurated products
          uncurated_products =
            Products.top_n_paginated(
              %{
                before: nil,
                after: nil
              },
              9,
              false
            )

          seller =
            case socket.assigns.current_user do
              nil ->
                nil

              %{id: id} ->
                Accounts.get_seller_by_id(id)
            end

          socket
          |> assign(top_products: top_products)
          |> assign(curated_products: curated_products.entries)
          |> assign(curated_cursor_after: curated_products.metadata.after)
          |> assign(curated_cursor_before: nil)
          |> assign(uncurated_products: uncurated_products.entries)
          |> assign(uncurated_cursor_after: uncurated_products.metadata.after)
          |> assign(uncurated_cursor_before: nil)
          |> assign(header: :landing)
          |> assign(seller: seller)
          |> assign(waiting: false)

        false ->
          socket
          |> assign(waiting: true)
      end

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
      Products.top_n_paginated(
        %{
          before: nil,
          after: socket.assigns.curated_cursor_after
        },
        3,
        true
      )

    socket =
      socket
      |> assign(curated_products: curated_products.entries)
      |> assign(curated_cursor_before: curated_products.metadata.before)
      |> assign(curated_cursor_after: curated_products.metadata.after)

    {:noreply, socket}
  end

  def handle_event("curated-cursor-before", _, socket) do
    curated_products =
      Products.top_n_paginated(
        %{
          before: socket.assigns.curated_cursor_before,
          after: nil
        },
        3,
        true
      )

    socket =
      socket
      |> assign(curated_products: curated_products.entries)
      |> assign(curated_cursor_before: curated_products.metadata.before)
      |> assign(curated_cursor_after: curated_products.metadata.after)

    {:noreply, socket}
  end

  def handle_event("uncurated-cursor-after", _, socket) do
    uncurated_products =
      Products.top_n_paginated(
        %{
          before: nil,
          after: socket.assigns.uncurated_cursor_after
        },
        9,
        false
      )

    socket =
      socket
      |> assign(uncurated_products: uncurated_products.entries)
      |> assign(uncurated_cursor_before: uncurated_products.metadata.before)
      |> assign(uncurated_cursor_after: uncurated_products.metadata.after)

    {:noreply, socket}
  end

  def handle_event("uncurated-cursor-before", _, socket) do
    uncurated_products =
      Products.top_n_paginated(
        %{
          before: socket.assigns.uncurated_cursor_before,
          after: nil
        },
        9,
        false
      )

    socket =
      socket
      |> assign(uncurated_products: uncurated_products.entries)
      |> assign(uncurated_cursor_before: uncurated_products.metadata.before)
      |> assign(uncurated_cursor_after: uncurated_products.metadata.after)

    {:noreply, socket}
  end

  @impl true
  def render(%{waiting: true} = assigns) do
    ~H"""
    <div style="margin-top: 200px; display: flex; justify-content: center;">
      <img src="gif/loading.gif" class="is-loading" />
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <.desktop
      top_products={@top_products}
      curated_products={@curated_products}
      curated_cursor_before={@curated_cursor_before}
      curated_cursor_after={@curated_cursor_after}
      uncurated_products={@uncurated_products}
      uncurated_cursor_before={@uncurated_cursor_before}
      uncurated_cursor_after={@uncurated_cursor_after}
    />
    <.mobile
      top_products={@top_products}
      uncurated_products={@uncurated_products}
      uncurated_cursor_before={@uncurated_cursor_before}
      uncurated_cursor_after={@uncurated_cursor_after}
    />
    """
  end

  def desktop(assigns) do
    ~H"""
    <div
      class="is-landing-desktop has-font-3"
      style="margin-top: 150px; margin-left: 20px; margin-right: 20px;"
    >
      <div style="display: flex; justify-content: center;">
        <div style="display: flex; flex-direction: column; width: 100%; max-width: 1500px;">
          <div style="display: flex; margin-bottom: 150px;">
            <div style="margin-right: 75px;">
              <img src="/svg/big-yellow-circle.svg" style="width: 300px;" />
            </div>
            <div>
              <div style="font-size: 72px;">
                Apoie a comunidade criativa
              </div>
              <div style="font-size: 36px; max-width: 775px; margin-bottom: 25px;">
                Bem vindo ao plaza, aqui você encontra camisetas e posters de artistas independentes.
              </div>
              <div style="font-size: 36px; max-width: 775px;">
                Inscreva-se e venda seus designs hoje mesmo.
              </div>
            </div>
          </div>
          <div>
            <ProductComponent.products3 products={@top_products} />
          </div>
          <div style="display: flex; justify-content: center; margin-top: 125px; margin-bottom: 100px;">
            <div>
              <h2 style="font-size: 58px; margin-bottom: 25px;">
                Monetize seus projetos com camisetas e posters
              </h2>
              <h3 style="font-size: 32px; min-width: 300px; max-width: 1005px; line-height: 36px; margin-bottom: 25px;">
                Crie sua loja e comece a vender hoje mesmo, não tem nenhum custo.
              </h3>
              <h3 style="font-size: 32px; min-width: 300px; max-width: 670px; line-height: 36px; margin-bottom: 25px;">
                A produção é feita sobre demanda sem quantidade mínima, sem desperdícios e entregue direto para o cliente final.
              </h3>
              <h3 style="font-size: 32px; line-height: 36px; margin-bottom: 25px;">
                <.link navigate="/upload" style="text-decoration: underline;">
                  quero vender
                </.link>
              </h3>
            </div>
            <div style="min-width: 250px;">
              <img src="svg/star.svg" />
            </div>
          </div>
          <div style="display: flex; margin-bottom: 30px;">
            <div>
              <h4 style="font-size: 58px; line-height: 45px;">
                Theme Selection of the month
              </h4>
              <h5 style="font-size: 32px;">
                Envios do tema mês de fevereiro Carros e Veículos
              </h5>
            </div>
            <div style="margin-left: auto; margin-right: 120px; display: flex; position: relative; top: 45px;">
              <div style="margin-right: 55px;">
                <button :if={@curated_cursor_before} phx-click="curated-cursor-before">
                  <img src="/svg/yellow-circle.svg" style="position: absolute; width: 40px;" />
                  <div style="position: absolute; color: grey; font-size: 42px;">
                    <div style="position: relative; left: 4px; bottom: 15px;">
                      <%= "<" %>
                    </div>
                  </div>
                </button>
              </div>
              <div>
                <button :if={@curated_cursor_after} phx-click="curated-cursor-after">
                  <img src="/svg/yellow-circle.svg" style="position: absolute; width: 40px;" />
                  <div style="position: absolute; color: grey; font-size: 42px;">
                    <div style="position: relative; left: 7px; bottom: 15px;">
                      <%= ">" %>
                    </div>
                  </div>
                </button>
              </div>
            </div>
          </div>
          <div>
            <ProductComponent.products3 products={@curated_products} />
          </div>
          <div id="top-products-desktop" style="margin-bottom: 100px;" />
          <div style="margin-bottom: 25px;">
            <h4 style="font-size: 58px; line-height: 45px;">
              Todos os produtos
            </h4>
            <h5 style="font-size: 32px;">
              Estampas da comunidade
            </h5>
          </div>
          <div>
            <ProductComponent.products3 products={@uncurated_products} />
          </div>
          <div style="display: flex; justify-content: space-around;  margin-bottom: 250px;">
            <div style="margin-right: 50px;">
              <a
                :if={@uncurated_cursor_before}
                phx-click="uncurated-cursor-before"
                class="has-font-3"
                style="font-size: 28px; text-decoration: underline;"
                href="#top-products-desktop"
              >
                anterior
              </a>
            </div>
            <div>
              <a
                :if={@uncurated_cursor_after}
                phx-click="uncurated-cursor-after"
                class="has-font-3"
                style="font-size: 28px; text-decoration: underline;"
                href="#top-products-desktop"
              >
                próxima
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mobile(assigns) do
    ~H"""
    <div class="is-landing-mobile has-font-3" style="margin-top: 25px;">
      <div style="display: flex; justify-content: center; margin-left: 10px; margin-right: 10px;">
        <div style="display: flex; flex-direction: column; width: 100%;">
          <div style="margin-left: 10px; margin-right: 10px;">
            <div style="font-size: 24px; line-height: 26px;">
              <h1>
                Bem vindo ao plaza,
              </h1>
              <h2>
                aqui você encontra camisetas e posters
              </h2>
              <h2>
                de artistas independentes.
              </h2>
            </div>
            <div style="display: flex; justify-content: center; margin-top: 25px; margin-bottom: 25px;">
              <div style="width: 30%; margin-right: 25px;">
                <img src="/svg/yellow-rectangle.svg" style="width: 100%;" />
              </div>
              <div style="width: 37%; margin-right: 25px;">
                <img src="/svg/big-yellow-ellipse.svg" style="width: 100%;" />
              </div>
              <div style="width: 33%;">
                <img src="/svg/yellow-polygon.svg" style="width: 100%;" />
              </div>
            </div>
            <h2 style="font-size: 32px; line-height: 34px;">
              Apoie a comunidade criativa
            </h2>
            <h2 style="font-size: 24px;  margin-bottom: 50px;">
              Compre de artistas independentes
            </h2>
          </div>
          <div style="display: flex; overflow-x: scroll; margin-bottom: 100px; padding-top: 15px;">
            <div :for={product <- @top_products} style="margin-right: 15px;">
              <ProductComponent.product
                product={product}
                meta={true}
                disabled={false}
                style="width: 315px;"
              />
            </div>
          </div>
          <div style="border-top: 1px solid lightgrey; border-bottom: 1px solid lightgrey;">
            <div style="margin-left: 20px;">
              <div style="font-size: 32px; line-height: 34px; margin-top: 35px; margin-bottom: 17px;">
                <h2>
                  Para Artistas
                </h2>
              </div>
              <div style="margin-bottom: 25px;">
                <img src="/svg/big-yellow-circle.svg" style="width: 140px;" />
              </div>
              <div style="font-size: 32px; line-height: 34px;">
                <h2>
                  Inscreva-se e venda seus
                </h2>
              </div>
              <div style="font-size: 32px; line-height: 34px;margin-bottom: 25px;">
                <h2>
                  designs hoje mesmo.
                </h2>
              </div>
              <div
                style="font-size: 24px; text-decoration: underline; margin-bottom: 75px;"
                id="top-products"
              >
                <.link navigate="/how-it-works/seller">
                  Saiba como funciona
                </.link>
              </div>
            </div>
          </div>
          <div style="font-size: 22px; line-height: 24px; display: flex; margin-top: 50px; margin-bottom: 50px; margin-left: 10px;">
            <div style="position: relative; margin-right: 20px;">
              <img src="/svg/arrow-down.svg" />
            </div>
            <div>
              <h3>
                Arraste para ver
              </h3>
              <h3>
                todos os produtos online
              </h3>
            </div>
          </div>
          <div style="padding-left: 10px; padding-right: 10px;">
            <div :for={product <- @uncurated_products} style="margin-bottom: 50px;">
              <ProductComponent.product product={product} meta={true} disabled={false} />
            </div>
          </div>
          <div style="display: flex; justify-content: space-around; margin-top: 25px; margin-bottom: 250px;">
            <div style="margin-right: 50px;">
              <a
                :if={@uncurated_cursor_before}
                phx-click="uncurated-cursor-before"
                class="has-font-3"
                style="font-size: 20px; text-decoration: underline;"
                href="#top-products"
              >
                anterior
              </a>
            </div>
            <div>
              <a
                :if={@uncurated_cursor_after}
                phx-click="uncurated-cursor-after"
                class="has-font-3"
                style="font-size: 20px; text-decoration: underline;"
                href="#top-products"
              >
                próxima
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
