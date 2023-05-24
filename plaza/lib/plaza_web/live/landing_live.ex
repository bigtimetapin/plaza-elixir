defmodule PlazaWeb.LandingLive do
  use PlazaWeb, :live_view

  on_mount {PlazaWeb.UserAuth, :mount_current_user}

  import PlazaWeb.ProductComponent

  alias Plaza.Products
  alias PlazaWeb.UserAuth

  def mount(_params, session, socket) do
    my_products =
      case socket.assigns.current_user do
        nil ->
          []

        %{id: id} ->
          Products.list_products_by_user_id(id)
      end

    socket =
      socket
      |> assign(:page_title, "Hello Plaza")
      |> assign(:header, :landing)
      |> assign(
        :products,
        [
          %{name: "camiseta", price: "99"},
          %{name: "outra camiseta", price: "79"},
          %{name: "sua camiseta", price: "89"},
          %{name: "tu tranqi", price: "59"},
          %{name: "bastante", price: "199"}
        ]
      )
      |> assign(:my_products, my_products)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="mt-large mx-large">
      <div class="is-size-1-desktop is-size-2-touch mb-medium mt-large">onde artistas vestem</div>
      <div class="is-size-3-desktop is-size-4-touch">
        <div class="mb-small">produtos em alta</div>
      </div>
      <.products products={@products}></.products>
    </div>
    """
  end
end
