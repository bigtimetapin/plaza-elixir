defmodule PlazaWeb.LandingLive do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias Plaza.Products
  alias PlazaWeb.ProductComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    IO.inspect(socket.assigns.current_user)
    ## curated products 
    top_3_curated_products =
      Products.top_n_paginated(
        %{
          before: nil,
          after: nil
        },
        3
      )

    next_9_curated_products =
      Products.top_n_paginated(
        %{
          before: nil,
          after: top_3_curated_products.metadata.after
        },
        9
      )

    seller =
      case socket.assigns.current_user do
        nil ->
          nil

        %{id: id} ->
          Accounts.get_seller_by_id(id)
      end

    socket =
      socket
      |> assign(top_3_curated_products: top_3_curated_products.entries)
      |> assign(next_9_curated_products: next_9_curated_products.entries)
      |> assign(curated_cursor_after: next_9_curated_products.metadata.after)
      |> assign(curated_cursor_before: nil)
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
    next_9_curated_products =
      Products.top_n_paginated(
        %{
          before: nil,
          after: socket.assigns.curated_cursor_after
        },
        9
      )

    socket =
      socket
      |> assign(next_9_curated_products: next_9_curated_products.entries)
      |> assign(curated_cursor_before: next_9_curated_products.metadata.before)
      |> assign(curated_cursor_after: next_9_curated_products.metadata.after)

    {:noreply, socket}
  end

  def handle_event("curated-cursor-before", _, socket) do
    next_9_curated_products =
      Products.top_n_paginated(
        %{
          before: socket.assigns.curated_cursor_before,
          after: nil
        },
        9
      )

    socket =
      socket
      |> assign(next_9_curated_products: next_9_curated_products.entries)
      |> assign(curated_cursor_before: next_9_curated_products.metadata.before)
      |> assign(curated_cursor_after: next_9_curated_products.metadata.after)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div
      class="is-landing-desktop has-font-3"
      style="margin-top: 150px; margin-left: 20px; margin-right: 20px;"
    >
      <div style="display: flex; justify-content: center;">
        <div style="display: flex; flex-direction: column; width: 100%; max-width: 1500px;">
          <div style="display: flex; margin-bottom: 100px;">
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
            <ProductComponent.products3 products={@top_3_curated_products} />
          </div>
          <div style="display: flex; justify-content: center; margin-top: 100px; margin-bottom: 100px;">
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
          <div style="display: flex; margin-bottom: 20px;">
            <div>
              <h4 style="font-size: 58px; line-height: 45px;">
                Designs Selecionados
              </h4>
              <h5 style="font-size: 32px;">
                As estampas que a gente mais gosta
              </h5>
            </div>
            <div style="margin-left: auto; margin-right: 120px; display: flex; position: relative; top: 45px;">
              <div style="margin-right: 50px;">
                <button
                  :if={@curated_cursor_before}
                  phx-click="curated-cursor-before"
                  class="has-font-3"
                  style="font-size: 28px; text-decoration: underline;"
                >
                  anterior
                </button>
              </div>
              <div>
                <button
                  :if={@curated_cursor_after}
                  phx-click="curated-cursor-after"
                  class="has-font-3"
                  style="font-size: 28px; text-decoration: underline;"
                >
                  próxima
                </button>
              </div>
            </div>
          </div>
          <div>
            <ProductComponent.products3 products={@next_9_curated_products} />
          </div>
          <div style="display: flex; justify-content: space-around; margin-top: 25px; margin-bottom: 250px;">
            <div style="margin-right: 50px;">
              <button
                :if={@curated_cursor_before}
                phx-click="curated-cursor-before"
                class="has-font-3"
                style="font-size: 28px; text-decoration: underline;"
              >
                anterior
              </button>
            </div>
            <div>
              <button
                :if={@curated_cursor_after}
                phx-click="curated-cursor-after"
                class="has-font-3"
                style="font-size: 28px; text-decoration: underline;"
              >
                próxima
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mobile(assigns) do
    ~H"""
    <div class="is-landing-mobile has-font-3" style="margin-top: 150px;">
      <div style="display: flex; justify-content: center;">
        <div style="display: flex; flex-direction: column; text-align: center; width: 100%;">
          <div style="padding-left: 10px; padding-right: 10px;">
            <div :for={product <- @curated_products} style="margin-bottom: 150px;">
              <ProductComponent.product product={product} meta={true} disabled={false} />
            </div>
            <div style="display: flex; justify-content: right; margin-top: 500px;">
              <div>
                <div style="font-size: 22px;">
                  em alta esta semana
                </div>
                <div style="margin-left: 10px;">
                  <img src="/svg/right-arrow.svg" />
                </div>
              </div>
            </div>
            <div style="display: flex; overflow-x: scroll; margin-bottom: 200px; padding-top: 15px;">
              <div
                :for={product <- @first_4_uncurated_products ++ @second_4_uncurated_products}
                style="margin-right: 15px;"
              >
                <ProductComponent.product
                  product={product}
                  meta={true}
                  disabled={false}
                  style="width: 355px;"
                />
              </div>
            </div>
          </div>
          <div>
            <h2 style="font-size: 40px; line-height: 55px; margin-bottom: 50px;">
              <div>
                plazaaaaa é uma loja aberta
              </div>
              <div>
                para vender camisetas
              </div>
              <div>
                estampadas
              </div>
            </h2>
            <div style="display: flex; justify-content: center; margin-bottom: 50px;">
              <img src="svg/star.svg" />
            </div>
            <h3 style="font-size: 20px; line-height: 28px; margin-bottom: 25px;">
              <div>
                qualquer um pode publicar seus designs e vender
              </div>
              <div>
                por aqui, basta escolher sua margem de lucro e
              </div>
              <div>
                subir a arte, o resto a gente cuida.
              </div>
            </h3>
            <h3 style="font-size: 20px; line-height: 28px; margin-bottom: 25px;">
              <div>
                cada produto vendido é produzido sob demanda e
              </div>
              <div>
                chega na casa do cliente final em até 7 dias úteis.
              </div>
            </h3>
            <h3 style="font-size: 20px; line-height: 28px; margin-bottom: 25px;">
              <div>
                produzimos sob demanda e não tem desperdício,
              </div>
              <div>
                você recebe seus lucros e basicamente é isso, bem
              </div>
              <div>
                simples e facil como tudo deveria ser.
              </div>
            </h3>
            <div style="margin-bottom: 250px;">
              <.link navigate="/upload" style="text-decoration: underline; font-size: 28px;">
                quero vender
              </.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
