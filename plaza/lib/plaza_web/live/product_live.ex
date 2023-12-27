defmodule PlazaWeb.ProductLive do
  use PlazaWeb, :live_view

  require Logger

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
  @site "https://plazaaaaa-solitary-snowflake-7144-summer-wave-9195.fly.dev"

  @local_storage_key "plaza-checkout-cart"

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
          |> assign(cart: [])
          |> assign(cart_product_size: "m")
          |> assign(cart_product_quantity: 1)
          |> push_event(
            "read",
            %{
              key: @local_storage_key,
              event: "read-cart"
            }
          )
      else
        socket
        |> assign(waiting: true)
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"product-id" => product_id} = params, uri, socket) do
    socket =
      if connected?(socket) do
        {product, seller} =
          case Products.get_product(product_id) do
            nil ->
              {nil, nil}

            product ->
              case Accounts.get_seller_by_id(product.user_id) do
                nil ->
                  {nil, nil}

                seller ->
                  {product, seller}
              end
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
  def handle_event("add-to-cart", _, socket) do
    cart = socket.assigns.cart
    product = socket.assigns.product
    size = socket.assigns.cart_product_size
    quantity = socket.assigns.cart_product_quantity

    item = %{
      product: product,
      size: size,
      quantity: quantity
    }

    cart = [item | cart]
    cart = Enum.uniq_by(cart, fn i -> i.product.id end)

    socket =
      socket
      |> push_event(
        "write",
        %{
          key: @local_storage_key,
          data: serialize_to_token(cart)
        }
      )
      |> assign(cart: cart)

    {:noreply, socket}
  end

  def handle_event("change-size", %{"size" => size}, socket) do
    socket =
      socket
      |> assign(cart_product_size: size)

    {:noreply, socket}
  end

  def handle_event("change-quantity", %{"op" => operator}, socket) do
    quantity = socket.assigns.cart_product_quantity

    quantity =
      case operator do
        "add" -> quantity + 1
        "subtract" -> quantity - 1
      end

    socket =
      socket
      |> assign(cart_product_quantity: quantity)

    {:noreply, socket}
  end

  defp serialize_to_token(state_data) do
    salt = Application.get_env(:plaza, PlazaWeb.Endpoint)[:live_view][:signing_salt]
    Phoenix.Token.encrypt(PlazaWeb.Endpoint, salt, state_data)
  end

  def handle_event("read-cart", token_data, socket) when is_binary(token_data) do
    socket =
      case restore_from_token(token_data) do
        {:ok, nil} ->
          # do nothing with the previous state
          socket

        {:ok, restored} ->
          socket
          |> assign(cart: restored)

        {:error, reason} ->
          # We don't continue checking. Display error.
          # Clear the token so it doesn't keep showing an error.
          socket
          |> put_flash(:error, reason)
          |> clear_browser_storage()
      end

    {:noreply, socket}
  end

  def handle_event("read-cart", _token_data, socket) do
    Logger.debug("No (valid) cart to restore")
    {:noreply, socket}
  end

  defp restore_from_token(nil), do: {:ok, nil}

  defp restore_from_token(token) do
    salt = Application.get_env(:plaza, PlazaWeb.Endpoint)[:live_view][:signing_salt]
    # Max age is 1 day. 86,400 seconds
    case Phoenix.Token.decrypt(PlazaWeb.Endpoint, salt, token, max_age: 86_400) do
      {:ok, data} ->
        {:ok, data}

      {:error, reason} ->
        # handles `:invalid`, `:expired` and possibly other things?
        {:error, "Failed to restore previous state. Reason: #{inspect(reason)}."}
    end
  end

  # Push a websocket event down to the browser's JS hook.
  # Clear any settings for the current my_storage_key.
  defp clear_browser_storage(socket) do
    push_event(socket, "clear", %{key: @local_storage_key})
  end

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
      "product-id" => product.id,
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
          <div style="align-self: center; display: flex;">
            <div>
              <button phx-click="add-to-cart">
                <img src="svg/yellow-ellipse.svg" />
                <div class="has-font-3" style="position: relative; bottom: 79px; font-size: 36px;">
                  Add to cart
                </div>
              </button>
            </div>
            <div style="margin-left: 10px;">
              <div>
                <button
                  phx-click="change-size"
                  phx-value-size="s"
                  style={
                    if @cart_product_size == "s",
                      do: "font-size: 44px; margin-left: 5px",
                      else: "margin-left: 5px"
                  }
                >
                  S
                </button>
                <button
                  phx-click="change-size"
                  phx-value-size="m"
                  style={
                    if @cart_product_size == "m",
                      do: "font-size: 44px; margin-left: 5px",
                      else: "margin-left: 5px"
                  }
                >
                  M
                </button>
                <button
                  phx-click="change-size"
                  phx-value-size="l"
                  style={if @cart_product_size == "l", do: "font-size: 44px;"}
                >
                  L
                </button>
              </div>
              <div style="display: flex;">
                <div>
                  <button phx-click="change-quantity" phx-value-op="add">
                    +
                  </button>
                  <button
                    :if={@cart_product_quantity > 0}
                    phx-click="change-quantity"
                    phx-value-op="subtract"
                  >
                    -
                  </button>
                </div>
                <div style="border: 1px solid grey; width: 50px; text-align: center; margin-left: 5px;">
                  <%= @cart_product_quantity %>
                </div>
              </div>
            </div>
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
