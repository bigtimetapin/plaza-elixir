defmodule PlazaWeb.ProductComponent do
  use Phoenix.Component

  def product(assigns) do
    ~H"""
    <div class="columns is-multiline is-size-8">
      <%= for product <- @products do %>
        <div class="column is-one-quarter is-product-1 has-font-3 mr-medium mb-medium">
          <div style="position: absolute; bottom: 0px;"><%= product.name %></div>
          <div class="pr-xsmall" style="position: absolute; bottom: 0px; right: 0px;">
            R$ <%= product.price %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
