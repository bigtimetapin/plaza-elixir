defmodule PlazaWeb.LandingLive do
  use PlazaWeb, :live_view

  def mount(params, session, socket) do
    socket = socket
             |> assign(:page_title, "Hello Plaza")
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
end
