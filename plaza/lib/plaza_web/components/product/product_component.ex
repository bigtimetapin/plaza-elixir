defmodule PlazaWeb.ProductComponent do
  use Phoenix.Component

  def products(assigns) do
    ~H"""
    <div class="columns is-multiline is-size-8">
      <%= for product <- @products do %>
        <div class="column is-one-quarter">
          <.product product={product} />
        </div>
      <% end %>
    </div>
    """
  end

  attr :selected, :boolean, default: false
  attr :product, :map, required: true
  attr :rest, :global

  def selectable(assigns) do
    ~H"""
    <div class={if @selected, do: "is-selected-product-1"}>
      <.product product={@product} disabled={false} {@rest} />
    </div>
    """
  end

  attr :disabled, :boolean, default: true
  attr :product, :map, required: true
  attr :rest, :global

  defp product(assigns) do
    ~H"""
    <button class="is-product-1 has-font-3 mr-medium mb-medium" disabled={@disabled} {@rest}>
      <div style="position: absolute; bottom: 0px; left: 10px;"><%= @product.name %></div>
      <div class="pr-xsmall" style="position: absolute; bottom: 0px; right: 0px;">
        R$ <%= @product.price %>
      </div>
    </button>
    """
  end
end
