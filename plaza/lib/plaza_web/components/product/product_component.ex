defmodule PlazaWeb.ProductComponent do
  use Phoenix.Component

  attr :products, :list, required: true

  def products3(assigns) do
    ~H"""
    <div class="columns is-multiline is-size-6 has-three-products">
      <%= for product <- @products do %>
        <div class="column is-one-third">
          <.productp product={product} meta={true} disabled={false} />
        </div>
      <% end %>
    </div>
    """
  end

  attr :products, :list, required: true

  def products4(assigns) do
    ~H"""
    <div class="columns is-multiline is-size-6 has-four-products">
      <%= for product <- @products do %>
        <div class="column is-one-quarter">
          <.productp product={product} meta={true} disabled={false} />
        </div>
      <% end %>
    </div>
    """
  end

  attr :product, :map, required: true
  attr :meta, :boolean, required: true

  def product(assigns) do
    ~H"""
    <.productp product={@product} meta={@meta} disabled={true} />
    """
  end

  attr :product, :map, required: true
  attr :meta, :boolean, required: true
  attr :disabled, :boolean, required: true
  attr :rest, :global

  defp productp(assigns) do
    product = assigns.product

    {days_remaining, expiring} =
      case product.active do
        true ->
          now = NaiveDateTime.utc_now()

          diff =
            NaiveDateTime.diff(
              product.campaign_duration_timestamp,
              now,
              :day
            )

          expiring = diff <= 2

          diff =
            case diff do
              0 -> "0.5"
              _ -> diff
            end

          {"Disponível por mais #{diff} dias", expiring}

        false ->
          {"expired", false}
      end

    assigns =
      assigns
      |> assign(days_remaining: days_remaining)
      |> assign(expiring: expiring)

    ~H"""
    <div style="height: calc(428px + 105px);">
      <div
        :if={@expiring}
        style="position: absolute; z-index: 99; width: 150px; transform: rotate(-16deg);"
      >
        <img src="svg/yellow-ellipse.svg" />
        <div class="has-font-3" style="position: relative; bottom: 59px; left: 11px; font-size: 30px;">
          Últimos dias
        </div>
      </div>
      <button
        class="is-product-1 has-font-3 mr-medium mb-medium"
        disabled={@disabled}
        phx-click={if !@disabled, do: "product-href"}
        phx-value-product-id={if !@disabled, do: "#{@product.id}"}
        {@rest}
      >
        <div>
          <img
            src={
              if @product.designs.display == 0, do: @product.mocks.front, else: @product.mocks.back
            }
            style="width: 100%;"
          />
        </div>
        <div :if={@meta} style="position: relative; top: 56px;">
          <div style="position: absolute; bottom: 25px; left: 10px;"><%= @product.name %></div>
          <div class="pr-xsmall" style="position: absolute; bottom: 25px; right: 0px;">
            <%= "R$ #{@product.price}" %>
          </div>
          <div
            class="has-dark-gray-text is-size-7"
            style="position: absolute; bottom: 0px; left: 10px;"
          >
            <%= @product.user_name %>
          </div>
          <div
            class="has-dark-gray-text is-size-7"
            style="position: absolute; bottom: 0px; right: 0px;"
          >
            <%= @days_remaining %>
          </div>
        </div>
      </button>
    </div>
    """
  end
end
