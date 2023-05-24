defmodule PlazaWeb.MyStoreLive do
  use PlazaWeb, :live_view

  alias Plaza.Products
  alias PlazaWeb.ProductComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    my_products = Products.list_products_by_user_id(socket.assigns.current_user.id)

    socket =
      socket
      |> assign(:header, :my_store)
      |> assign(:my_products, my_products)

    IO.inspect(my_products)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div style="margin-bottom: 50px;">
      <.left />
      <.right my_products={@my_products} />
    </div>
    """
  end

  defp left(assigns) do
    ~H"""
    <div class="has-font-3" style="display: inline-block; position: relative; top: 50px;">
      <div>
        <img src="images/pep.png" style="width: 377px;" />
      </div>
      <div style="position: relative; left: 61px; width: 316px; height: 423px; border-right: 1px solid #707070;">
        <div class="is-size-6 mb-small" style="text-decoration: underline;">
          username
        </div>
        <div class="is-size-6 mb-xsmall" style="line-height: 34px; width: 267px;">
          Breve descrição do artista. Maximo 140 caracteres.
        </div>
        <div class="is-size-6 mb-small has-dark-gray-text">
          Localização do artista.
        </div>
        <div class="is-size-6" style="text-decoration: underline;">
          Instagram
        </div>
        <div class="is-size-6" style="text-decoration: underline;">
          Email
        </div>
        <div class="is-size-6" style="text-decoration: underline;">
          Soundcloud
        </div>
        <div class="is-size-6" style="text-decoration: underline;">
          Website
        </div>
        <div class="is-size-6" style="text-decoration: underline;">
          Twitter
        </div>
      </div>
    </div>
    """
  end

  defp right(assigns) do
    ~H"""
    <div style="display: inline-block;">
      <div style="position: relative; left: 75px; bottom: 175px;">
        <ProductComponent.products3 products={@my_products} />
      </div>
      <div
        class="has-font-3"
        style="display: flex; justify-content: flex-end; position: relative; top: 50px;"
      >
        <div style="display: inline-block; position: relative; right: 200px;">
          <div class="is-size-6" style="text-decoration: underline;">
            Ver todos as produtos
          </div>
        </div>
        <div style="display: inline-block; position: relative; left: 50px;">
          <div class="is-size-6 has-dark-gray-text" style="text-decoration: underline;">
            Acessar Painel de Vendedor
          </div>
        </div>
      </div>
    </div>
    """
  end
end
