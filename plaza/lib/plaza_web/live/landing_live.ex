defmodule PlazaWeb.LandingLive do
  use PlazaWeb, :live_view

  import PlazaWeb.ProductComponent

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Hello Plaza")
      |> assign(:header, :landing)
      |> assign(
        :products,
        [
          %{name: "camiseta", price: "99"},
          %{name: "minha seta", price: "79"},
          %{name: "sua seta", price: "89"},
          %{name: "tu tranqi", price: "59"},
          %{name: "bastante", price: "199"}
        ]
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="mt-large">
      <div class="is-size-3-desktop is-size-4-touch mb-medium mt-large">onde artistas vestem</div>
      <div class="is-size-5-desktop is-size-6-touch">
        <div class="mb-small">produtos em alta</div>
      </div>
      <.product products={@products}></.product>
    </div>
    """
  end
end
