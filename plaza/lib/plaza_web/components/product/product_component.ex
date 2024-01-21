defmodule PlazaWeb.ProductComponent do
  use Phoenix.Component

  attr :products, :list, required: true

  def products3(assigns) do
    ~H"""
    <div class="columns is-multiline" style="max-width: 1500px;">
      <%= for product <- @products do %>
        <div class="column is-one-third" style="margin-bottom: 100px;">
          <.product product={product} meta={true} disabled={false} />
        </div>
      <% end %>
    </div>
    """
  end

  attr :products, :list, required: true

  def products4(assigns) do
    ~H"""
    <div class="columns is-multiline" style="max-width: 1600px;">
      <%= for product <- @products do %>
        <div class="column is-one-quarter-widescreen is-one-third-desktop is-half-tablet">
          <.product product={product} meta={true} disabled={false} />
        </div>
      <% end %>
    </div>
    """
  end

  attr :product, :map, required: true
  attr :meta, :boolean, required: true
  attr :disabled, :boolean, required: true
  attr :rest, :global

  def product(assigns) do
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
    <div class="is-product-1" {@rest}>
      <div style="position: absolute;">
        <button
          class="has-font-3"
          disabled={@disabled}
          phx-click={if !@disabled, do: "product-href"}
          phx-value-product-id={if !@disabled, do: "#{@product.id}"}
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
      <div
        :if={@expiring}
        style="position: absolute; z-index: 99; width: 150px; transform: rotate(-16deg);"
      >
        <div style="position: relative; right: 22px; bottom: 10px;">
          <img src="svg/yellow-ellipse.svg" style="position: absolute;" />
          <div
            class="has-font-3"
            style="position: absolute; font-size: 30px; margin-top: 15px; margin-left: 11px;"
          >
            Últimos dias
          </div>
        </div>
      </div>
    </div>
    """
  end
end
