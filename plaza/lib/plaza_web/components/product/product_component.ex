defmodule PlazaWeb.ProductComponent do
  use Phoenix.Component

  attr :disabled, :boolean, default: true
  attr :products, :list, required: true
  attr :href, :boolean, default: false

  def products3(assigns) do
    ~H"""
    <div class="columns is-multiline is-size-6 has-three-products">
      <%= for product <- @products do %>
        <div class="column is-one-third">
          <.productp product={product} disabled={@disabled} href={@href} />
        </div>
      <% end %>
    </div>
    """
  end

  def products4(assigns) do
    ~H"""
    <div class="columns is-multiline is-size-6 has-four-products">
      <%= for product <- @products do %>
        <div class="column is-one-quarter">
          <.productp product={product} />
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
      <.productp product={@product} disabled={false} {@rest} />
    </div>
    """
  end

  attr :product, :map, required: true

  def product(assigns) do
    ~H"""
    <.productp product={@product} />
    """
  end

  attr :disabled, :boolean, default: true
  attr :product, :map, required: true
  attr :href, :boolean, default: false
  attr :rest, :global

  defp productp(assigns) do
    ~H"""
    <button
      class="is-product-1 has-font-3 mr-medium mb-medium"
      disabled={@disabled}
      phx-click={if @href, do: "product-href"}
      phx-value-product-name={if @href, do: "#{@product.name}"}
      {@rest}
    >
      <div>
        <img src={Map.get(@product, :front_url)} style="width: 100%;" />
      </div>
      <div style="position: absolute; bottom: 25px; left: 10px;"><%= @product.name %></div>
      <div class="pr-xsmall" style="position: absolute; bottom: 25px; right: 0px;">
        <%= if Map.get(@product, :price), do: "R$ #{@product.price}" %>
      </div>
      <div class="has-dark-gray-text is-size-7" style="position: absolute; bottom: 0px; left: 10px;">
        username
      </div>
    </button>
    """
  end
end
