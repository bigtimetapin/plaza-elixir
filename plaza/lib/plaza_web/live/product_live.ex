defmodule PlazaWeb.ProductLive do
  use PlazaWeb, :live_view

  alias Ecto.Changeset

  alias Plaza.Accounts
  alias Plaza.Accounts.Address
  alias Plaza.Accounts.Seller
  alias Plaza.Dimona
  alias Plaza.Products
  alias PlazaWeb.ProductComponent

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket =
      if connected?(socket) do
        socket
      else
        socket
        |> assign(waiting: true)
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"user-name" => user_name, "product-name" => product_name}, _uri, socket) do
    socket =
      if connected?(socket) do
        seller = Accounts.get_seller_by_user_name(user_name)
        IO.inspect(seller)

        product =
          case seller do
            nil ->
              nil

            nnil ->
              Products.get_product(
                seller.user_id,
                product_name
              )
          end

        IO.inspect(product)

        socket
        |> assign(seller: seller)
        |> assign(product: product)
        |> assign(step: 1)
        |> assign(waiting: false)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("step", %{"step" => "2"}, socket) do
    user_id =
      case socket.assigns.current_user do
        nil -> nil
        current_user -> current_user.id
      end

    socket =
      socket
      |> assign(step: 2)
      |> assign(
        address_form:
          to_form(
            Address.changeset(
              %Address{
                user_id: user_id
              },
              %{}
            )
          )
      )

    {:noreply, socket}
  end

  def handle_event("change-address-form", params, socket) do
    {:noreply, socket}
  end

  def handle_event("submit-address-form", %{"address" => attrs}, socket) do
    changes =
      Address.changeset(
        %Address{},
        attrs
      )
      |> Changeset.apply_action(:update)

    socket =
      case changes do
        {:error, changeset} ->
          socket
          |> assign(address_form: changeset |> to_form)

        {:ok, address} ->
          Task.async(fn ->
            {
              :shipping_quote,
              Dimona.Requests.Shipping.post(%{
                "zipcode" => address.postal_code,
                "quantity" => 1
              })
            }
          end)

          socket
          |> assign(shipping_address: address)
          |> assign(waiting: true)
      end

    {:noreply, socket}
  end

  def handle_event("select-shipping-option", %{"id" => id, "price" => price}, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({ref, {:shipping_quote, result}}, socket) do
    Process.demonitor(ref, [:flush])

    result =
      case result do
        {:error, payload} ->
          IO.inspect(payload)

          :error

        {:ok, many} ->
          case many do
            [] ->
              :error

            nel ->
              {:ok, nel}
          end
      end

    socket =
      case result do
        :error ->
          socket
          |> assign(error: "unable to resolve cep, try again")
          |> assign(shipping_options: nil)

        {:ok, nel} ->
          socket
          |> assign(shipping_options: nel)
          |> assign(error: nil)
      end

    socket =
      socket
      |> assign(step: 3)
      |> assign(waiting: false)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(%{waiting: true} = assigns) do
    ~H"""
    <div style="margin-top: 150px;">
      <div style="display: flex; justify-content: center;">
        waiting
      </div>
    </div>
    """
  end

  def render(%{product: nil} = assigns) do
    ~H"""
    <div>
      <div style="display: flex; justify-content: center;">
        product does not exist
      </div>
    </div>
    """
  end

  def render(%{product: product, step: 1} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div style="display: flex; flex-direction: column;">
          <ProductComponent.product product={product} />
          <div style="align-self: center;">
            <button phx-click="step" phx-value-step="2">
              <img src="svg/yellow-ellipse.svg" />
              <div class="has-font-3" style="position: relative; bottom: 79px; font-size: 36px;">
                Purchase
              </div>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(%{product: product, step: 2} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div style="display: flex; flex-direction: column;">
          <div>
            <ProductComponent.product product={product} />
          </div>
          <div style="align-self: center;">
            shipping address
          </div>
          <div>
            <.form
              for={@address_form}
              phx-change="change-address-form"
              phx-submit="submit-address-form"
            >
              <.input
                field={@address_form[:line1]}
                type="text"
                placeholder="endereço"
                class="text-input-1"
                autocomplete="shipping address-line1"
              >
              </.input>
              <.input
                field={@address_form[:line2]}
                type="text"
                placeholder="complemento"
                class="text-input-1"
                autocomplete="shipping address-line2"
              >
              </.input>
              <.input
                field={@address_form[:postal_code]}
                type="text"
                placeholder="cep"
                class="text-input-1"
                autocomplete="shipping postal-code"
              >
              </.input>
              <div style="display: flex; justify-content: center; margin-top: 50px;">
                <button>
                  <img src="svg/yellow-ellipse.svg" />
                  <div class="has-font-3" style="position: relative; bottom: 79px; font-size: 36px;">
                    Submit
                  </div>
                </button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(%{product: product, step: 3, shipping_options: nil, error: error} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div>
          <ProductComponent.product product={product} />
        </div>
        <div style="display: flex; flex-direction: column;">
          <div>
            here
          </div>
          <div>
            and here
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(%{product: product, step: 3, shipping_options: shipping_options} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div>
          <ProductComponent.product product={product} />
        </div>
        <div style="display: flex; flex-direction: column; position: relative; top: 100px; left: 50px;">
          <button
            :for={opt <- shipping_options}
            phx-click="select-shipping-option"
            phx-value-id={opt.delivery_method_id}
            phx-value-price={opt.value}
            style="margin-top: 15px;"
          >
            <%= "#{opt.name}: #{opt.value}" %>
          </button>
        </div>
      </div>
    </div>
    """
  end
end
