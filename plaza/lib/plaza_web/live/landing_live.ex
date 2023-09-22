defmodule PlazaWeb.LandingLive do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias PlazaWeb.ProductComponent

  def mount(_params, session, socket) do
    seller =
      case socket.assigns.current_user do
        nil ->
          nil

        %{id: id} ->
          Accounts.get_seller_by_id(id)
      end

    socket =
      socket
      |> assign(:page_title, "Hello Plaza")
      |> assign(:header, :landing)
      |> assign(
        :products,
        [
          %{name: "camiseta", price: "99", designs: %{}},
          %{name: "outra camiseta", price: "79", designs: %{}},
          %{name: "sua camiseta", price: "89", designs: %{}},
          %{name: "tu tranqi", price: "59", designs: %{}},
          %{name: "bastante", price: "199", designs: %{}}
        ]
      )
      |> assign(:seller, seller)

    IO.inspect(socket.assigns)

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
