defmodule PlazaWeb.CheckoutLive do
  use PlazaWeb, :live_view

  require Logger

  alias Ecto.Changeset

  alias Plaza.Accounts
  alias Plaza.Accounts.Address
  alias Plaza.Dimona
  alias Plaza.Products.Product
  alias Plaza.Purchases

  @site "http://localhost:4000"
  ## @site "https://plazaaaaa-solitary-snowflake-7144-summer-wave-9195.fly.dev"

  @local_storage_key "plaza-checkout-cart"

  @sku_map %{
    "white-s" => "010101110108",
    "white-m" => "010101110109",
    "white-l" => "010101110110"
  }

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      case connected?(socket) do
        false ->
          socket
          |> assign(waiting: true)

        true ->
          {socket, user_id} =
            case socket.assigns.current_user do
              nil ->
                {
                  socket
                  |> assign(
                    login_form:
                      to_form(
                        %{
                          "email" => nil,
                          "redirect_url" => "/checkout"
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

          seller =
            case user_id do
              nil ->
                nil

              id ->
                Accounts.get_seller_by_id(id)
            end

          socket
          |> assign(seller: seller)
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
          |> assign(waiting: false)
          |> push_event(
            "read",
            %{
              key: @local_storage_key,
              event: "read-cart"
            }
          )
      end

    socket =
      socket
      |> assign(cart: [])
      |> assign(cart_empty: true)
      |> assign(cart_out_of_stock: false)
      |> assign(cart_total_amount: 0)
      |> assign(header: :checkout)
      |> assign(step: 1)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"purchase-id" => purchase_id, "success" => "true"} = params, _uri, socket) do
    case connected?(socket) do
      true ->
        purchase = Purchases.get!(purchase_id)

        Task.async(fn ->
          {:ok, stripe_session} = Stripe.Session.retrieve(purchase.stripe_session_id)

          {:ok, payment_intent} =
            Stripe.PaymentIntent.retrieve(stripe_session.payment_intent, %{})

          charges = List.first(payment_intent.charges.data)

          payment_status = payment_intent.status
          payment_status = Purchases.normalize_payment_status(payment_status)
          {:payment_status, payment_status}
        end)

      false ->
        purchase = Purchases.get!(purchase_id)

        Phoenix.PubSub.subscribe(
          Plaza.PubSub,
          "payment-status-#{purchase.id}"
        )
    end

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("read-cart", token_data, socket) when is_binary(token_data) do
    socket =
      case restore_from_token(token_data) do
        {:ok, nil} ->
          # do nothing with the previous state
          socket

        {:ok, cart} ->
          cart_empty = Enum.empty?(cart)

          cart_total_amount =
            List.foldl(cart, 0, fn item, acc -> item.product.price * item.quantity + acc end)

          Enum.each(cart, fn item ->
            Task.async(fn ->
              sku = Map.get(@sku_map, "white-#{item.size}")
              {:ok, value} = Dimona.Requests.Availability.get(sku)
              {:availability, item.product.id, value}
            end)
          end)

          IO.inspect(cart)

          socket
          |> assign(cart: cart)
          |> assign(cart_empty: cart_empty)
          |> assign(cart_total_amount: cart_total_amount)

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

  defp serialize_to_token(state_data) do
    salt = Application.get_env(:plaza, PlazaWeb.Endpoint)[:live_view][:signing_salt]
    Phoenix.Token.encrypt(PlazaWeb.Endpoint, salt, state_data)
  end

  def handle_event("change-size", %{"size" => size, "product-id" => product_id}, socket) do
    cart = socket.assigns.cart
    product_id = String.to_integer(product_id)

    {item, index} =
      Enum.with_index(cart)
      |> Enum.find(fn {item, _} -> item.product.id == product_id end)

    item = %{item | size: size}
    cart = List.replace_at(cart, index, item)
    cart_empty = Enum.empty?(cart)

    cart_total_amount =
      List.foldl(cart, 0, fn item, acc -> item.product.price * item.quantity + acc end)

    Enum.each(cart, fn item ->
      Task.async(fn ->
        sku = Map.get(@sku_map, "white-#{item.size}")
        {:ok, value} = Dimona.Requests.Availability.get(sku)
        {:availability, item.product.id, value}
      end)
    end)

    socket =
      socket
      |> assign(cart: cart)
      |> assign(cart_empty: cart_empty)
      |> assign(cart_total_amount: cart_total_amount)
      |> push_event(
        "write",
        %{
          key: @local_storage_key,
          data: serialize_to_token(cart)
        }
      )

    {:noreply, socket}
  end

  def handle_event("change-quantity", %{"op" => operator, "product-id" => product_id}, socket) do
    cart = socket.assigns.cart
    product_id = String.to_integer(product_id)

    {item, index} =
      Enum.with_index(cart)
      |> Enum.find(fn {item, _} -> item.product.id == product_id end)

    quantity = item.quantity

    quantity =
      case operator do
        "add" -> quantity + 1
        "subtract" -> quantity - 1
      end

    item = %{item | quantity: quantity}
    cart = List.replace_at(cart, index, item)
    cart_empty = Enum.empty?(cart)

    cart_total_amount =
      List.foldl(cart, 0, fn item, acc -> item.product.price * item.quantity + acc end)

    Enum.each(cart, fn item ->
      Task.async(fn ->
        sku = Map.get(@sku_map, "white-#{item.size}")
        {:ok, value} = Dimona.Requests.Availability.get(sku)
        {:availability, item.product.id, value}
      end)
    end)

    socket =
      socket
      |> assign(cart: cart)
      |> assign(cart_empty: cart_empty)
      |> assign(cart_total_amount: cart_total_amount)
      |> push_event(
        "write",
        %{
          key: @local_storage_key,
          data: serialize_to_token(cart)
        }
      )

    {:noreply, socket}
  end

  def handle_event("remove-from-cart", %{"product-id" => product_id}, socket) do
    cart = socket.assigns.cart
    product_id = String.to_integer(product_id)

    {_, index} =
      Enum.with_index(cart)
      |> Enum.find(fn {item, _} -> item.product.id == product_id end)

    cart = List.delete_at(cart, index)
    cart_empty = Enum.empty?(cart)
    cart_out_of_stock = Enum.any?(cart, fn i -> !i.available end)

    cart_total_amount =
      List.foldl(cart, 0, fn item, acc -> item.product.price * item.quantity + acc end)

    socket =
      socket
      |> assign(cart: cart)
      |> assign(cart_empty: cart_empty)
      |> assign(cart_total_amount: cart_total_amount)
      |> assign(cart_out_of_stock: cart_out_of_stock)
      |> push_event(
        "write",
        %{
          key: @local_storage_key,
          data: serialize_to_token(cart)
        }
      )

    {:noreply, socket}
  end

  def handle_event("product-href", %{"product-id" => product_id}, socket) do
    params = %{"product-id" => product_id}
    url = URI.encode_query(params)
    {:noreply, push_navigate(socket, to: "/product?#{url}")}
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

  def handle_event("checkout", _, socket) do
    Task.async(fn ->
      cart = socket.assigns.cart

      products =
        Enum.map(
          cart,
          fn item ->
            IO.inspect(item)

            %{
              product_id: item.product.id,
              user_id: item.product.user_id,
              size: item.size,
              quantity: item.quantity,
              price: item.product.price
            }
          end
        )

      sellers =
        List.foldl(products, [], fn item, acc ->
          case Enum.find(acc |> Enum.with_index(), fn {i, _} -> i.user_id == item.user_id end) do
            nil ->
              new = %{
                user_id: item.user_id,
                total_price: item.price * item.quantity,
                total_quantity: item.quantity,
                paid: false
              }

              [new | acc]

            {found, index} ->
              new = %{
                found
                | total_price: found.total_price + item.price * item.quantity,
                  total_quantity: found.total_quantity + item.quantity
              }

              acc = List.replace_at(acc, index, new)
              acc
          end
        end)

      delivery_method = socket.assigns.delivery_method
      shipping_address = socket.assigns.shipping_address
      email = socket.assigns.email
      name = socket.assigns.name

      user_id =
        case socket.assigns.current_user do
          nil -> nil
          current_user -> current_user.id
        end

      {:ok, purchase} =
        Purchases.create(%{
          user_id: user_id,
          products: products,
          sellers: sellers,
          sellers_paid: false,
          email: email,
          stripe_session_id: "pending",
          shipping_method_id: delivery_method.id,
          shipping_method_price: delivery_method.price,
          shipping_address_line1: shipping_address.line1,
          shipping_address_line2: shipping_address.line2,
          shipping_address_postal_code: shipping_address.postal_code
        })

      params = %{
        "purchase-id" => purchase.id
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

      create_stripe_product_stream =
        Task.async_stream(cart, fn item ->
          product = item.product

          mock_url =
            if product.designs.display == 0, do: product.mocks.front, else: product.mocks.back

          {:ok, stripe_product} =
            Stripe.Product.create(%{
              images: [mock_url],
              name: product.name,
              url: "#{@site}/product?product_id=#{product.id}",
              default_price_data: %{
                unit_amount: Product.price_unit_amount(product),
                currency: "brl"
              }
            })

          %{stripe_product: stripe_product, quantity: item.quantity}
        end)

      stripe_products = Enum.to_list(create_stripe_product_stream)

      line_items =
        Enum.map(
          stripe_products,
          fn {:ok, item} ->
            %{
              price: item.stripe_product.default_price,
              quantity: item.quantity
            }
          end
        )

      transfer_group = UUID.uuid1()

      {:ok, stripe_session} =
        Stripe.Session.create(%{
          mode: "payment",
          line_items: line_items,
          payment_intent_data: %{
            receipt_email: email,
            metadata: %{"purchase_id" => purchase.id},
            transfer_group: transfer_group
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
          success_url: "#{@site}/checkout?#{success_query_params}",
          cancel_url: "#{@site}/checkout?#{cancel_query_params}"
        })

      IO.inspect(stripe_session)

      {:ok, purchase} =
        Purchases.update(
          purchase,
          %{"stripe_session_id" => stripe_session.id}
        )

      {:stripe_redirect, stripe_session.url}
    end)

    socket =
      socket
      |> assign(waiting: true)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "2"}, socket) do
    socket =
      socket
      |> assign(step: 2)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "3"}, socket) do
    socket =
      socket
      |> assign(step: 3)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({ref, {:availability, product_id, value}}, socket) do
    Process.demonitor(ref, [:flush])
    cart = socket.assigns.cart

    {item, index} =
      Enum.with_index(cart)
      |> Enum.find(fn {item, _} -> item.product.id == product_id end)

    supply = Map.values(value) |> List.first()

    available = item.quantity + 5 <= supply
    item = %{item | available: available}
    cart = List.replace_at(cart, index, item)
    cart_out_of_stock = Enum.any?(cart, fn i -> !i.available end)

    socket =
      socket
      |> assign(cart: cart)
      |> assign(cart_out_of_stock: cart_out_of_stock)

    {:noreply, socket}
  end

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
          IO.inspect(nel)

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

  def handle_info({ref, {:stripe_redirect, url}}, socket) do
    Process.demonitor(
      ref,
      [:flush]
    )

    socket =
      socket
      |> redirect(external: url)

    {:noreply, socket}
  end

  ## from task
  def handle_info({ref, {:payment_status, payment_status}}, socket) do
    Process.demonitor(
      ref,
      [:flush]
    )

    socket =
      case payment_status do
        "succeeded" ->
          socket
          |> assign(cart: [])
          |> assign(cart_empty: true)
          |> assign(cart_total_amount: 0)
          |> assign(step: 5)
          |> push_event(
            "clear",
            %{
              key: @local_storage_key
            }
          )

        _ ->
          socket
      end

    {:noreply, socket}
  end

  ## from pubsub
  def handle_info({:payment_status, payment_status}, socket) do
    socket =
      case payment_status do
        "suceeded" ->
          socket
          |> assign(cart: [])
          |> assign(cart_empty: true)
          |> assign(cart_total_amount: 0)
          |> assign(step: 5)
          |> push_event(
            "clear",
            %{
              key: @local_storage_key
            }
          )

        _ ->
          socket
      end

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

  def render(%{step: 1, cart: []} = assigns) do
    ~H"""
    <div
      class="has-font-3"
      style="margin-top: 150px; margin-bottom: 150px; display: flex; justify-content: center;"
    >
      <div style="display: flex; flex-direction: column; text-align: center;">
        <div style="font-size: 40px;">
          Seu carrinho está vazio
        </div>
        <div style="font-size: 40px;">
          <.link navigate="/" style="text-decoration: underline;">
            Voltar para Loja
          </.link>
        </div>
      </div>
    </div>
    """
  end

  def render(%{step: 1} = assigns) do
    ~H"""
    <div class="has-font-3" style="margin-top: 150px; margin-bottom: 150px; display: flex;">
      <div style="margin-left: 50px; font-size: 44px;">
        <div style="display: flex; border-bottom: 2px solid grey; width: 800px;">
          <div>
            carrinho
          </div>
          <div style="margin-left: 100px;">
            item
          </div>
          <div style="margin-left: auto; margin-right: 10px;">
            valor
          </div>
        </div>
        <div style="margin-top: 20px;">
          <div :for={item <- @cart} style="display: flex;">
            <div style="width: 100px;">
              <button phx-click="product-href" phx-value-product-id={item.product.id}>
                <img src={
                  if item.product.designs.display == 0,
                    do: item.product.mocks.front,
                    else: item.product.mocks.back
                } />
              </button>
            </div>
            <div style="margin-left: 127px;">
              <div style="font-size: 32px;">
                <%= item.product.name %>
              </div>
              <div style="font-size: 28px; color: grey;">
                <button
                  phx-click="change-size"
                  phx-value-size="s"
                  phx-value-product-id={item.product.id}
                  style={
                    if item.size == "s",
                      do: "font-size: 38px; margin-left: 5px",
                      else: "margin-left: 5px"
                  }
                >
                  S
                </button>
                <button
                  phx-click="change-size"
                  phx-value-size="m"
                  phx-value-product-id={item.product.id}
                  style={
                    if item.size == "m",
                      do: "font-size: 38px; margin-left: 5px",
                      else: "margin-left: 5px"
                  }
                >
                  M
                </button>
                <button
                  phx-click="change-size"
                  phx-value-size="l"
                  phx-value-product-id={item.product.id}
                  style={if item.size == "l", do: "font-size: 38px;"}
                >
                  L
                </button>
              </div>
            </div>
            <div style="margin-left: auto; margin-right: 10px;">
              <div style="font-size: 28px;">
                <%= "R$ #{String.replace(Float.to_string(item.product.price), ".", ",")}" %>
              </div>
              <div :if={item.available} style="display: flex; font-size: 22px; margin-top: 5px;">
                <div>
                  <button
                    phx-click="change-quantity"
                    phx-value-op="add"
                    phx-value-product-id={item.product.id}
                  >
                    +
                  </button>
                  <button
                    :if={item.quantity > 1}
                    phx-click="change-quantity"
                    phx-value-op="subtract"
                    phx-value-product-id={item.product.id}
                  >
                    -
                  </button>
                </div>
                <div style="border: 1px solid grey; width: 40px; text-align: center; margin-left: 5px;">
                  <%= item.quantity %>
                </div>
              </div>
              <div :if={!item.available} style="font-size: 22px; margin-top: 5px;">
                out of stock
              </div>
              <div>
                <button
                  style="font-size: 18px; color: grey; position: relative; bottom: 25px;"
                  phx-click="remove-from-cart"
                  phx-value-product-id={item.product.id}
                >
                  remover
                </button>
              </div>
            </div>
          </div>
        </div>
        <div :if={!@cart_empty}>
          <div style="display: flex; border-bottom: 2px solid grey; width: 800px;"></div>
          <div style="display: flex; font-size: 28px;">
            <div>
              valor dos prodotus
            </div>
            <div style="margin-left: auto; margin-right: 10px;">
              <%= "R$ #{Float.to_string(@cart_total_amount) |> String.replace(".", ",")}" %>
            </div>
          </div>
          <div style="display: flex; font-size: 28px;">
            <div>
              valor do frete
            </div>
            <div style="margin-left: auto; margin-right: 10px;">
              calculado no checkout
            </div>
          </div>
        </div>
      </div>
      <div style="margin-left: 50px; font-size: 44px;">
        <.sign_in_or_continue_as_guest
          current_user={@current_user}
          cart_empty={@cart_empty}
          cart_out_of_stock={@cart_out_of_stock}
          login_form={assigns[:login_form]}
          email_form={assigns[:email_form]}
          email_form_is_empty={assigns[:email_form_is_empty]}
        />
      </div>
    </div>
    """
  end

  defp sign_in_or_continue_as_guest(%{current_user: nil} = assigns) do
    ~H"""
    <div :if={!@cart_empty} style="display: flex; justify-content: center;">
      <div style="margin-left: 150px;">
        <div style="font-size: 40px;">
          checkout
        </div>
        <div style="font-size: 22px;">
          coloque seu email para fazer login
        </div>
        <div>
          <PlazaWeb.Auth.Login.login_quick form={@login_form} redirect_url="/checkout" />
        </div>
        <div>
          <div style="font-size: 22px;">
            ou continue como convidado
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

  defp sign_in_or_continue_as_guest(assigns) do
    ~H"""
    <div
      :if={!@cart_empty}
      style="display: flex; justify-content: center; width: 500px; margin-top: 150px;"
    >
      <button
        phx-click="step"
        phx-value-step="2"
        style={if @cart_out_of_stock, do: "opacity: 50%"}
        disabled={@cart_out_of_stock}
      >
        <img src="svg/yellow-ellipse.svg" />
        <div class="has-font-3" style="position: relative; bottom: 79px; font-size: 36px;">
          checkout
        </div>
      </button>
    </div>
    """
  end

  def render(%{step: 2} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
        <div style="display: flex; flex-direction: column;">
          <div style="align-self: center; font-size: 40px;">
            Entrega
          </div>
          <div style="align-self: center; font-size: 22px;">
            coloque o endereço para entrega do seu pedido
          </div>
          <div style="margin-bottom: 50px;">
            <.form for={@name_form} phx-change="change-name-form">
              <.input
                field={@name_form[:name]}
                type="text"
                placeholder="nome"
                class="text-input-1"
                autocomplete="name"
                phx-debounce="500"
              >
              </.input>
            </.form>
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
                phx-debounce="500"
              >
              </.input>
              <.input
                field={@address_form[:line2]}
                type="text"
                placeholder="complemento"
                class="text-input-1"
                autocomplete="shipping address-line2"
                phx-debounce="500"
              >
              </.input>
              <.input
                field={@address_form[:postal_code]}
                type="text"
                placeholder="cep"
                class="text-input-1"
                autocomplete="shipping postal-code"
                phx-debounce="500"
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

  def render(%{delivery_methods: nil, error: error} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
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

  def render(%{step: 3, delivery_methods: delivery_methods} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
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

  def render(%{step: 4} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 200px;">
      <div style="display: flex; justify-content: center;">
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

  def render(%{step: 5} = assigns) do
    ~H"""
    <div
      class="has-font-3"
      style="margin-top: 150px; margin-bottom: 150px; display: flex; justify-content: center;"
    >
      <div style="display: flex; flex-direction: column; text-align: center;">
        <div style="font-size: 36px;">
          Compra realizada com sucesso!
        </div>
        <div style="font-size: 30px; margin-top: 10px;">
          check your email for your receipt and updates
        </div>
        <div style="display: flex; justify-content: center; margin-top: 50px;">
          <div style="display: flex; flex-direction: column; width: 300px;">
            <img src="svg/yellow-ellipse.svg" />
            <div class="has-font-3" style="position: relative; bottom: 115px; font-size: 55px;">
              Successo!
            </div>
          </div>
        </div>
        <div style="font-size: 30px; margin-top: 10px;">
          Ficou alguma dúvida? clique aqui
        </div>
      </div>
    </div>
    """
  end
end
