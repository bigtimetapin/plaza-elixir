defmodule PlazaWeb.ProductLive do
  use PlazaWeb, :live_view

  alias Ecto.Changeset

  alias Plaza.Accounts
  alias Plaza.Accounts.Address
  alias Plaza.Accounts.Seller
  alias Plaza.Dimona
  alias Plaza.Products
  alias Plaza.Products.Product
  alias Plaza.Purchases
  alias PlazaWeb.ProductComponent

  ## @site "http://localhost:4000"
  @site "https://plazaaaaa.fly.dev"

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket =
      if connected?(socket) do
        {socket, user_id} =
          case socket.assigns.current_user do
            nil ->
              {
                socket
                |> assign(
                  login_form:
                    to_form(
                      %{
                        "email" => nil
                      },
                      as: "user"
                    )
                )
                |> assign(
                  email_form:
                    to_form(
                      %{
                        "email" => nil
                      },
                      as: "email-form"
                    )
                )
                |> assign(email: nil)
                |> assign(email_form_is_empty: true),
                nil
              }

            current_user ->
              {
                socket
                |> assign(email: current_user.email),
                current_user.id
              }
          end

        socket =
          socket
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
          |> assign(
            name_form:
              to_form(
                %{
                  "name" => nil
                },
                as: "name-form"
              )
          )
          |> assign(name: nil)
      else
        socket
        |> assign(waiting: true)
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(
        %{"user-name" => user_name, "product-name" => product_name} = params,
        uri,
        socket
      ) do
    socket =
      if connected?(socket) do
        seller = Accounts.get_seller_by_user_name(user_name)

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

        socket =
          socket
          |> assign(seller: seller)
          |> assign(product: product)
          |> assign(uri: uri)

        case params do
          %{"success" => "true", "email" => email, "purchase-id" => purchase_id} ->
            purchase = Purchases.get!(purchase_id)

            Phoenix.PubSub.subscribe(
              Plaza.PubSub,
              "payment-status-#{purchase.id}"
            )

            Task.async(fn ->
              {:ok, stripe_session} =
                stripe_session = Stripe.Session.retrieve(purchase.stripe_session_id)

              {:ok, payment_intent} =
                Stripe.PaymentIntent.retrieve(stripe_session.payment_intent, %{})

              IO.inspect(payment_intent)

              IO.inspect(stripe_session)

              payment_status = payment_intent.status
              payment_status = Purchases.normalize_payment_status(payment_status)
              {:payment_status, payment_status}
            end)

            socket
            |> assign(email: email)
            |> assign(step: 5)
            |> assign(payment_status: "processing")
            |> assign(waiting: false)

          %{"cancel" => "true", "email" => email, "purchase-id" => purchase_id} ->
            purchase = Purchases.get!(purchase_id)

            socket
            |> assign(email: email)
            |> assign(step: 1)
            |> assign(waiting: false)

          _ ->
            case seller do
              %{stripe_id: nil} ->
                socket
                |> assign(step: -1)
                |> assign(waiting: false)

              _ ->
                case product do
                  %{active: false} ->
                    socket
                    |> assign(step: -2)
                    |> assign(waiting: false)

                  _ ->
                    socket
                    |> assign(step: 1)
                    |> assign(waiting: false)
                end
            end
        end
      else
        socket
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("step", %{"step" => "2"}, socket) do
    socket =
      socket
      |> assign(step: 2)

    {:noreply, socket}
  end

  def handle_event("checkout", _params, socket) do
    product = socket.assigns.product
    delivery_method = socket.assigns.delivery_method
    shipping_address = socket.assigns.shipping_address
    email = socket.assigns.email

    user_id =
      case socket.assigns.current_user do
        nil -> nil
        current_user -> current_user.id
      end

    {:ok, purchase} =
      Purchases.create(%{
        user_id: user_id,
        product_id: product.id,
        email: email,
        stripe_session_id: "pending",
        dimona_delivery_method_id: delivery_method.id,
        shipping_address_line1: shipping_address.line1,
        shipping_address_line2: shipping_address.line2,
        shipping_address_city: shipping_address.city,
        shipping_address_state: shipping_address.state,
        shipping_address_postal_code: shipping_address.postal_code,
        shipping_address_country: shipping_address.country
      })

    params = %{
      "purchase-id" => purchase.id,
      "user-name" => socket.assigns.seller.user_name,
      "product-name" => product.name,
      "email" => email
    }

    success_query_params =
      URI.encode_query(
        Map.put(
          params,
          "success",
          true
        )
      )

    cancel_query_params =
      URI.encode_query(
        Map.put(
          params,
          "cancel",
          true
        )
      )

    {:ok, stripe_product} =
      Stripe.Product.create(%{
        images:
          [product.designs.front, product.designs.back]
          |> Enum.filter(&(!is_nil(&1))),
        name: product.name,
        url: socket.assigns.uri,
        default_price_data: %{
          unit_amount: Product.price_unit_amount(product),
          currency: "brl"
        }
      })

    {:ok, stripe_session} =
      Stripe.Session.create(%{
        mode: "payment",
        line_items: [
          %{
            price: stripe_product.default_price,
            quantity: 1
          }
        ],
        payment_intent_data: %{
          ## 50 cents times 100 == 50
          application_fee_amount: 50 * 100,
          transfer_data: %{
            destination: socket.assigns.seller.stripe_id
          },
          receipt_email: email,
          metadata: %{"purchase_id" => purchase.id}
        },
        shipping_options: [
          %{
            shipping_rate_data: %{
              type: "fixed_amount",
              fixed_amount: %{
                amount: delivery_method.price,
                currency: "brl"
              },
              display_name: delivery_method.name,
              delivery_estimate: %{
                maximum: %{
                  unit: "business_day",
                  value: delivery_method.days
                }
              }
            }
          }
        ],
        customer_email: email,
        success_url: "#{@site}/product?#{success_query_params}",
        cancel_url: "#{@site}/product?#{cancel_query_params}"
      })

    IO.inspect(stripe_session)

    {:ok, purchase} =
      Purchases.update(
        purchase,
        %{"stripe_session_id" => stripe_session.id}
      )

    socket =
      socket
      |> redirect(external: stripe_session.url)

    {:noreply, socket}
  end

  def handle_event("change-email-form", %{"email-form" => %{"email" => email}}, socket) do
    is_empty =
      case email do
        "" -> true
        _ -> false
      end

    socket =
      socket
      |> assign(email_form_is_empty: is_empty)

    {:noreply, socket}
  end

  def handle_event("submit-email-form", %{"email-form" => %{"email" => email}}, socket) do
    socket =
      socket
      |> assign(email: email)
      |> assign(step: 2)

    {:noreply, socket}
  end

  def handle_event("change-name-form", %{"name-form" => %{"name" => name}}, socket) do
    socket =
      socket
      |> assign(name: name)

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

  def handle_event(
        "select-delivery-method",
        %{"id" => id, "price" => price, "name" => name, "days" => days},
        socket
      ) do
    {price, _} = Float.parse(price)
    price = (price * 100) |> Kernel.round()

    socket =
      socket
      |> assign(
        delivery_method: %{
          id: id,
          price: price,
          name: name,
          days: days
        }
      )
      |> assign(step: 4)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({ref, {:shipping_quote, result}}, socket) do
    Process.demonitor(ref, [:flush])

    result =
      case result do
        {:error, payload} ->
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
          |> assign(delivery_methods: nil)

        {:ok, nel} ->
          socket
          |> assign(delivery_methods: nel)
          |> assign(error: nil)
      end

    socket =
      socket
      |> assign(step: 3)
      |> assign(waiting: false)

    {:noreply, socket}
  end

  ## from task
  def handle_info({ref, {:payment_status, payment_status}}, socket) do
    Process.demonitor(
      ref,
      [:flush]
    )

    socket =
      socket
      |> assign(payment_status: payment_status)

    {:noreply, socket}
  end

  ## from pubsub
  def handle_info({:payment_status, payment_status}, socket) do
    socket =
      socket
      |> assign(payment_status: payment_status)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(%{waiting: true} = assigns) do
    ~H"""
    <div style="margin-top: 200px; display: flex; justify-content: center;">
      <img src="gif/loading.gif" />
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

  def render(%{product: product, step: -1} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div>
          <ProductComponent.product product={product} meta={true} />
        </div>
        <div>
          this seller has not finished registration yet
        </div>
      </div>
    </div>
    """
  end

  def render(%{product: product, step: -2} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div>
          <ProductComponent.product product={product} meta={true} />
        </div>
        <div>
          this product is no longer available
        </div>
      </div>
    </div>
    """
  end

  def render(%{product: product, email: nil, step: 1} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div>
          <ProductComponent.product product={product} meta={true} />
        </div>
        <div style="position: relative; top: 50px; margin-left: 50px;">
          <div>
            Press login to continue
          </div>
          <div>
            <PlazaWeb.Auth.Login.login_quick form={@login_form} />
          </div>
        </div>
        <div style="position: relative; top: 50px; margin-left: 50px; margin-right: 50px;">
          <div>
            or continue as guest
          </div>
          <div>
            <.form for={@email_form} phx-change="change-email-form" phx-submit="submit-email-form">
              <.input
                field={@email_form[:email]}
                type="email"
                placeholder="email"
                autocomplete="email"
              />
              <div style={if @email_form_is_empty, do: "opacity: 50%;"}>
                <div style="display: flex; justify-content: center; margin-top: 50px;">
                  <button disabled={@email_form_is_empty}>
                    <img src="svg/yellow-ellipse.svg" />
                    <div class="has-font-3" style="position: relative; bottom: 79px; font-size: 36px;">
                      Continue
                    </div>
                  </button>
                </div>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(%{product: product, step: 1} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div style="display: flex; flex-direction: column;">
          <ProductComponent.product product={product} meta={true} />
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
            <ProductComponent.product product={product} meta={true} />
          </div>
          <div style="align-self: center;">
            add name for the shipping label
          </div>
          <div style="margin-bottom: 50px;">
            <.form for={@name_form} phx-change="change-name-form">
              <.input
                field={@name_form[:name]}
                type="text"
                placeholder="name"
                class="text-input-1"
                autocomplete="name"
              >
              </.input>
            </.form>
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

  def render(%{product: product, step: 3, delivery_methods: nil, error: error} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div>
          <ProductComponent.product product={product} meta={true} />
        </div>
        <div style="display: flex; flex-direction: column;">
          <div>
            could not resolve your shipping address
          </div>
          <div>
            <button phx-click="step" phx-value-step="2">
              <img src="svg/yellow-ellipse.svg" />
              <div class="has-font-3" style="position: relative; bottom: 79px; font-size: 36px;">
                Try Again
              </div>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(%{product: product, step: 3, delivery_methods: delivery_methods} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div>
          <ProductComponent.product product={product} meta={true} />
        </div>
        <div style="display: flex; flex-direction: column; position: relative; top: 100px; left: 50px;">
          <button
            :for={opt <- delivery_methods}
            phx-click="select-delivery-method"
            phx-value-id={opt.delivery_method_id}
            phx-value-price={opt.value}
            phx-value-name={opt.name}
            phx-value-days={opt.business_days}
            style="margin-top: 15px;"
          >
            <%= "#{opt.name}: R$ #{opt.value} at #{opt.business_days} days" %>
          </button>
        </div>
      </div>
    </div>
    """
  end

  def render(%{product: product, step: 4} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div>
          <ProductComponent.product product={product} meta={true} />
        </div>
        <div style="display: flex; flex-direction: column; position: relative; top: 150px;">
          <div>
            <%= "#{@delivery_method.name}: R$ #{@delivery_method.price / 100.0}" %>
          </div>
          <div>
            <button phx-click="checkout">
              <img src="svg/yellow-ellipse.svg" />
              <div class="has-font-3" style="position: relative; bottom: 79px; font-size: 36px;">
                Checkout
              </div>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(%{product: product, step: 5, payment_status: "processing"} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div>
          <ProductComponent.product product={product} meta={true} />
        </div>
        <div style="display: flex; flex-direction: column; position: relative; top: 150px;">
          payment submitted. just waiting for approval.
        </div>
      </div>
    </div>
    """
  end

  def render(%{product: product, step: 5, payment_status: "succeeded"} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div>
          <ProductComponent.product product={product} meta={true} />
        </div>
        <div style="display: flex; flex-direction: column; position: relative; top: 150px;">
          payment approved. your t-shirt is on the way! be on the lookout for emails.
        </div>
      </div>
    </div>
    """
  end

  def render(%{product: product, step: 5, payment_status: "canceled"} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div>
          <ProductComponent.product product={product} meta={true} />
        </div>
        <div style="display: flex; flex-direction: column; position: relative; top: 150px;">
          payment canceled
        </div>
      </div>
    </div>
    """
  end

  def render(%{product: product, step: 5, payment_status: "error"} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div>
          <ProductComponent.product product={product} meta={true} />
        </div>
        <div style="display: flex; flex-direction: column; position: relative; top: 150px;">
          there was an issue with your payment. be on the lookout for emails.
        </div>
      </div>
    </div>
    """
  end
end
