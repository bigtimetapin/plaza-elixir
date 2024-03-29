defmodule PlazaWeb.CheckoutLive do
  use PlazaWeb, :live_view

  require Logger

  alias Ecto.Changeset

  alias Plaza.Accounts
  alias Plaza.Accounts.Address
  alias Plaza.Dimona
  alias Plaza.Products.Product
  alias Plaza.Purchases

  @local_storage_key "plaza-checkout-cart"
  @sku_map %{
    "white-p" => "010110110108",
    "white-m" => "010110110109",
    "white-g" => "010110110110",
    "white-gg" => "010110110111",
    "white-xgg" => "010110110112"
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
          |> assign(delivery_methods_error: false)
          |> assign(delivery_methods_waiting: false)
          |> assign(delivery_methods: nil)
          |> assign(delivery_method: nil)
          |> assign(
            name_form:
              to_form(
                %{
                  "name" => nil
                },
                as: "name-form"
              )
          )
          |> assign(name_form_valid: false)
          |> assign(name: nil)
          |> assign(checkout_as_guest_mobile: false)
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
        ## give time for stripe to post new status
        ## sleep outside task below to leave the page in waiting true
        Process.sleep(5000)

        Task.async(fn ->
          purchase = Purchases.get!(purchase_id)
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
  def handle_event("open-mobile-header", _, socket) do
    socket =
      socket
      |> assign(mobile_header_open: true)

    {:noreply, socket}
  end

  def handle_event("close-mobile-header", _, socket) do
    socket =
      socket
      |> assign(mobile_header_open: false)

    {:noreply, socket}
  end

  def handle_event("checkout-as-guest", _, socket) do
    checkout_as_guest_mobile = !socket.assigns.checkout_as_guest_mobile

    socket =
      socket
      |> assign(checkout_as_guest_mobile: checkout_as_guest_mobile)

    {:noreply, socket}
  end

  def handle_event("read-cart", token_data, socket) when is_binary(token_data) do
    socket =
      case restore_from_token(token_data) do
        {:ok, nil} ->
          # do nothing with the previous state
          socket

        {:ok, cart} ->
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

  def handle_event(
        "change-quantity",
        %{"op" => operator, "product-id" => product_id, "size" => size},
        socket
      ) do
    cart = socket.assigns.cart
    product_id = String.to_integer(product_id)

    {item, index} =
      Enum.with_index(cart)
      |> Enum.find(fn {item, _} -> item.product.id == product_id && item.size == size end)

    quantity = item.quantity

    quantity =
      case operator do
        "add" -> quantity + 1
        "subtract" -> quantity - 1
      end

    item = %{item | quantity: quantity}
    cart = List.replace_at(cart, index, item)

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

  def handle_event("remove-from-cart", %{"product-id" => product_id, "size" => size}, socket) do
    cart = socket.assigns.cart
    product_id = String.to_integer(product_id)

    {_, index} =
      Enum.with_index(cart)
      |> Enum.find(fn {item, _} -> item.product.id == product_id && item.size == size end)

    cart = List.delete_at(cart, index)
    cart_out_of_stock = Enum.any?(cart, fn i -> !i.available end)

    cart_total_amount =
      List.foldl(cart, 0, fn item, acc -> item.product.price * item.quantity + acc end)

    socket =
      socket
      |> assign(cart: cart)
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
      |> assign(email: email)
      |> assign(email_form_is_empty: is_empty)

    {:noreply, socket}
  end

  def handle_event("submit-email-form", _, socket) do
    socket =
      socket
      |> assign(step: 2)

    {:noreply, socket}
  end

  def handle_event("change-name-form", %{"name-form" => %{"name" => name} = attrs}, socket) do
    address_form = socket.assigns.address_form
    IO.inspect(address_form)
    IO.inspect(address_form.source.valid?)
    data = socket.assigns.name_form.data

    changes =
      {data, %{name: :string}}
      |> Changeset.cast(%{name: name}, [:name])
      |> Changeset.validate_required([:name])
      |> Changeset.apply_action(:update)

    socket =
      case changes do
        {:error, changeset} ->
          form = changeset |> to_form(as: "name-form")

          socket
          |> assign(name_form: form)
          |> assign(name_form_valid: false)

        {:ok, _} ->
          form =
            {%{name: name}, %{name: :string}}
            |> Changeset.cast(%{}, [])
            |> Map.put(:action, :validation)
            |> to_form(as: "name-form")

          socket
          |> assign(name_form: form)
          |> assign(name_form_valid: true)
      end

    socket =
      socket
      |> assign(name: name)

    {:noreply, socket}
  end

  def handle_event(
        "change-postal-code",
        %{"address" => %{"postal_code" => postal_code} = attrs},
        socket
      ) do
    IO.inspect(postal_code)
    attrs = %{"postal_code" => postal_code}
    address = socket.assigns.address_form.data

    changes =
      Address.changeset_postal_code(
        address,
        attrs
      )
      |> Changeset.apply_action(:update)

    socket =
      case changes do
        {:error, changeset} ->
          socket
          |> assign(address_form: changeset |> to_form())
          |> assign(delivery_methods_error: false)
          |> assign(delivery_methods: nil)
          |> assign(delivery_method: nil)

        {:ok, address} ->
          Task.async(fn ->
            cart = socket.assigns.cart

            total_quantity =
              List.foldl(
                cart,
                0,
                fn item, acc ->
                  item.quantity + acc
                end
              )

            {
              :shipping_quote,
              Dimona.Requests.Shipping.post(%{
                "zipcode" => address.postal_code,
                "quantity" => total_quantity
              })
            }
          end)

          address_form =
            Address.changeset(
              address,
              %{}
            )
            |> Map.put(:action, :validate)
            |> to_form()

          socket
          |> assign(address_form: address_form)
          |> assign(delivery_methods_waiting: true)
      end

    {:noreply, socket}
  end

  def handle_event("change-address-form", %{"address" => attrs}, socket) do
    address = socket.assigns.address_form.data
    IO.inspect(address)
    IO.inspect(attrs)

    changes =
      Address.changeset_no_postal_code(
        address,
        attrs
      )
      |> Changeset.apply_action(:update)

    form =
      case changes do
        {:error, changeset} ->
          changeset |> to_form()

        {:ok, address} ->
          Address.changeset(
            address,
            %{}
          )
          |> Map.put(:action, :validate)
          |> to_form()
      end

    socket =
      socket
      |> assign(address_form: form)

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
          |> assign(delivery_methods: nil)
          |> assign(error: nil)

        {:ok, address} ->
          send(self(), :checkout)

          socket
          |> assign(shipping_address: address)
      end

    {:noreply, socket}
  end

  def handle_event(
        "select-delivery-method",
        %{"id" => id, "price" => price, "name" => name, "days" => days},
        socket
      ) do
    {price, _} = Float.parse(price)
    price = price |> Kernel.round()

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

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "2"}, socket) do
    socket =
      socket
      |> assign(step: 2)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({ref, {:availability, product_id, value}}, socket) do
    Process.demonitor(ref, [:flush])
    cart = socket.assigns.cart

    ## race condition where read-cart/availability-check is fired off at mount-callback 
    ## but the handle-params callback on-purchase-success clears the cart 
    ## and this handler ends up with an empty cart
    socket =
      case cart do
        [] ->
          socket

        _ ->
          {item, index} =
            Enum.with_index(cart)
            |> Enum.find(fn {item, _} -> item.product.id == product_id end)

          supply = Map.values(value) |> List.first()

          available = item.quantity + 5 <= supply
          item = %{item | available: available}
          cart = List.replace_at(cart, index, item)
          cart_out_of_stock = Enum.any?(cart, fn i -> !i.available end)

          socket
          |> assign(cart: cart)
          |> assign(cart_out_of_stock: cart_out_of_stock)
      end

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

            [head | _] ->
              head = normalize_delivery_method(head)

              all =
                many
                |> Enum.map(fn opt ->
                  normalize_delivery_method(opt)
                end)

              {:ok, head, all}
          end
      end

    socket =
      case result do
        :error ->
          socket
          |> assign(delivery_methods_error: true)
          |> assign(delivery_methods: nil)
          |> assign(delivery_method: nil)

        {:ok, head, all} ->
          socket
          |> assign(delivery_methods: all)
          |> assign(delivery_method: head)
          |> assign(delivery_methods_error: false)
      end

    socket =
      socket
      |> assign(delivery_methods_waiting: false)

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

  def handle_info(:checkout, socket) do
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
              price: item.product.price,
              internal_expense: item.product.internal_expense
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
                total_platform_fee: item.internal_expense * item.quantity,
                product_analytics: [
                  %{
                    product_id: item.product_id,
                    quantity: item.quantity
                  }
                ],
                paid: false
              }

              [new | acc]

            {found, index} ->
              product_analytics =
                new = %{
                  found
                  | total_price: found.total_price + item.price * item.quantity,
                    total_quantity: found.total_quantity + item.quantity,
                    total_platform_fee:
                      found.total_platform_fee + item.internal_expense * item.quantity,
                    product_analytics: [
                      %{
                        product_id: item.product_id,
                        quantity: item.quantity
                      }
                      | found.product_analytics
                    ]
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
          customer_name: name,
          stripe_session_id: "pending",
          shipping_method_id: delivery_method.id,
          shipping_method_price: delivery_method.price,
          shipping_address_line1: shipping_address.line1,
          shipping_address_line2: shipping_address.line2,
          shipping_address_line3: shipping_address.line3,
          shipping_address_city: shipping_address.city,
          shipping_address_state: shipping_address.state,
          shipping_address_country: "br",
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

          product_url =
            "#{Application.get_env(:plaza, :app_url)}/product?product_id=#{product.id}"

          {:ok, stripe_product} =
            Stripe.Product.create(%{
              images: [mock_url],
              name: product.name,
              url: product_url,
              default_price_data: %{
                unit_amount: Product.price_unit_amount(product),
                currency: "brl"
              },
              metadata: %{
                url: product_url
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
          success_url:
            "#{Application.get_env(:plaza, :app_url)}/checkout?#{success_query_params}",
          cancel_url: "#{Application.get_env(:plaza, :app_url)}/checkout?#{cancel_query_params}"
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

  @impl Phoenix.LiveView
  def render(%{waiting: true} = assigns) do
    ~H"""
    <div style="display: flex; justify-content: center;">
      <img
        src="/gif/loading.gif"
        class="is-loading-desktop"
        style="margin-top: 200px; margin-bottom: 200px;"
      />
      <img
        src="/gif/loading-mobile.gif"
        class="is-loading-mobile"
        style="margin-top: 50px; margin-bottom: 50px;"
      />
    </div>
    """
  end

  def render(%{step: 1, cart: []} = assigns) do
    ~H"""
    <div class="is-checkout-page-desktop">
      <div
        class="has-font-3"
        style="margin-top: 250px; margin-bottom: 500px; display: flex; justify-content: center;"
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
    </div>
    <div class="is-checkout-page-mobile">
      <div
        class="has-font-3"
        style="margin-top: 250px; margin-bottom: 500px; display: flex; justify-content: center;"
      >
        <div style="display: flex; flex-direction: column; text-align: center;">
          <div style="font-size: 34px;">
            Seu carrinho está vazio
          </div>
          <div style="font-size: 34px;">
            <.link navigate="/" style="text-decoration: underline;">
              Voltar para Loja
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(%{step: 1} = assigns) do
    ~H"""
    <div class="is-checkout-page-desktop">
      <div
        class="has-font-3"
        style="margin-top: 150px; margin-bottom: 150px; display: flex; justify-content: center;"
      >
        <div style="display: flex; max-width: 1687px; width: 100%; margin-left: 10px;">
          <div style="font-size: 44px; width: 100%;">
            <div style="display: flex; border-bottom: 2px solid grey; width: 100%">
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
            <div style="margin-top: 20px; width: 100%;">
              <div :for={item <- @cart} style="display: flex;">
                <div style="width: 127px;">
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
                    <%= "Tamanho: #{String.upcase(item.size)}" %>
                  </div>
                </div>
                <div style="margin-left: auto; margin-right: 10px;">
                  <div style="font-size: 28px;">
                    <%= "R$ #{String.replace(Float.to_string(item.product.price), ".", ",")}" %>
                  </div>
                  <div
                    :if={item.available}
                    style="display: flex; font-size: 22px; justify-content: right;"
                  >
                    <div>
                      <button
                        phx-click="change-quantity"
                        phx-value-op="add"
                        phx-value-product-id={item.product.id}
                        phx-value-size={item.size}
                      >
                        +
                      </button>
                      <button
                        :if={item.quantity > 1}
                        phx-click="change-quantity"
                        phx-value-op="subtract"
                        phx-value-product-id={item.product.id}
                        phx-value-size={item.size}
                      >
                        -
                      </button>
                    </div>
                    <div style="border: 1px solid grey; width: 40px; text-align: center; margin-left: 5px;">
                      <%= item.quantity %>
                    </div>
                  </div>
                  <div :if={!item.available} style="font-size: 22px;">
                    out of stock
                  </div>
                  <div style="text-align: right;">
                    <button
                      style="font-size: 18px; color: grey; position: relative; bottom: 25px;"
                      phx-click="remove-from-cart"
                      phx-value-product-id={item.product.id}
                      phx-value-size={item.size}
                    >
                      remover
                    </button>
                  </div>
                </div>
              </div>
            </div>
            <div style="width: 100%; margin-bottom: 75px;">
              <div style="display: flex; border-bottom: 2px solid grey; width: 100%;"></div>
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
            <div style="display: flex;">
              <div style="margin-left: auto; margin-right: 61px; font-size: 32px; align-self: center;">
                <.link navigate="/" style="text-decoration: underline;">
                  voltar para loja
                </.link>
              </div>
              <button :if={@current_user} phx-click="step" phx-value-step="2">
                <img src="/svg/checkout.svg" />
              </button>
              <button :if={!@current_user} disabled style="opacity: 50%;">
                <img src="/svg/checkout.svg" />
              </button>
            </div>
          </div>
          <div
            :if={!@current_user}
            style="font-size: 44px; margin-left: 50px; margin-right: 10px; width: 100%;"
          >
            <.sign_in_or_continue_as_guest
              current_user={@current_user}
              cart_out_of_stock={@cart_out_of_stock}
              login_form={assigns[:login_form]}
              email_form={assigns[:email_form]}
              email_form_is_empty={assigns[:email_form_is_empty]}
            />
          </div>
        </div>
      </div>
    </div>
    <div class="is-checkout-page-mobile has-font-3">
      <div style="display: flex; justify-content: center; margin-left: 10px; margin-right: 10px; margin-top: 50px;">
        <div style="display: flex; flex-direction: column; width: 100%;">
          <div style="border-bottom: 2px solid grey; margin-bottom: 10px;">
            <div style="font-size: 36px; line-height: 40px; margin-left: 10px;">
              Carrinho
            </div>
          </div>
          <div style="border-bottom: 1px solid grey; display: flex; margin-left: 10px; margin-right: 10px; margin-bottom: 11px;">
            <div style="font-size: 22px; line-height: 40px; margin-left: 10px;">
              item
            </div>
            <div style="font-size: 22px; line-height: 40px; margin-left: auto; margin-right: 10px;">
              valor
            </div>
          </div>
          <div style="margin-left: 10px; margin-right: 10px;">
            <div :for={item <- @cart} style="border-bottom: 1px solid lightgrey; margin-top: 13px;">
              <div>
                <button phx-click="product-href" phx-value-product-id={item.product.id}>
                  <img src={
                    if item.product.designs.display == 0,
                      do: item.product.mocks.front,
                      else: item.product.mocks.back
                  } />
                </button>
              </div>
              <div style="font-size: 24px;">
                <%= item.product.name %>
              </div>
              <div style="font-size: 28px; display: flex;">
                <div style="color: grey;">
                  <%= "Tamanho: #{String.upcase(item.size)}" %>
                </div>
                <div style="margin-left: auto">
                  <%= "R$ #{(item.product.price * item.quantity) |> Float.to_string() |> String.replace(".", ",")}" %>
                </div>
              </div>
              <div :if={item.available} style="display: flex; font-size: 20px; margin-top: 5px;">
                <div style="margin-left: auto;">
                  <div style="display: flex;">
                    <div>
                      <button
                        phx-click="change-quantity"
                        phx-value-op="add"
                        phx-value-product-id={item.product.id}
                        phx-value-size={item.size}
                      >
                        +
                      </button>
                      <button
                        :if={item.quantity > 1}
                        phx-click="change-quantity"
                        phx-value-op="subtract"
                        phx-value-product-id={item.product.id}
                        phx-value-size={item.size}
                      >
                        -
                      </button>
                    </div>
                    <div style="border: 1px solid grey; width: 40px; text-align: center; margin-left: 5px;">
                      <%= item.quantity %>
                    </div>
                  </div>
                </div>
              </div>
              <div :if={!item.available} style="display: flex; font-size: 22px; margin-top: 5px;">
                <div style="margin-left: auto;">
                  out of stock
                </div>
              </div>
              <div style="font-size: 22px; color: grey; margin-bottom: 13px;">
                <a
                  class="has-font-3"
                  style="text-decoration: underline; color: grey;"
                  phx-click="remove-from-cart"
                  phx-value-product-id={item.product.id}
                  phx-value-size={item.size}
                  href="#top"
                >
                  remover
                </a>
              </div>
            </div>
            <div style="display: flex; margin-top: 7px;">
              <div style="margin-left: auto;">
                <div style="display: flex;">
                  <div style="font-size: 22px; margin-right: 14px; align-self: center;">
                    Total:
                  </div>
                  <div style="font-size: 32px;">
                    <%= "R$ #{Float.to_string(@cart_total_amount) |> String.replace(".", ",")}" %>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div :if={!@checkout_as_guest_mobile && !@current_user} style="margin-bottom: 50px;">
            <div style="border-bottom: 1px solid grey; margin-bottom: 17px; margin-top: 50px;">
              <div style="font-size: 36px; line-height: 40px; margin-left: 10px;">
                Checkout
              </div>
            </div>
            <div style="margin-left: 10px; padding-right: 20px; width: 100%;">
              <div style="font-size: 20px; line-height: 18px;">
                coloque seu email para fazer login
              </div>
              <div style="font-size: 20px; line-height: 18px; margin-bottom: 23px;">
                ou continue como
                <button
                  class="has-font-3"
                  style="text-decoration: underline;"
                  phx-click="checkout-as-guest"
                >
                  convidado
                </button>
              </div>
              <div style="display: flex; justify-content: center;">
                <PlazaWeb.Auth.Login.login_quick
                  form={@login_form}
                  redirect_url="/checkout"
                  button_right={false}
                  width="100%"
                />
              </div>
            </div>
          </div>
          <div :if={@checkout_as_guest_mobile && !@current_user}>
            <div style="border-bottom: 1px solid grey; margin-bottom: 10px; margin-top: 50px;">
              <div style="font-size: 36px; line-height: 40px; margin-left: 10px;">
                Checkout como convidado
              </div>
            </div>
            <div style="font-size: 20px; line-height: 18px; margin-left: 10px; margin-bottom: 10px;">
              coloque apenas seu email
            </div>
            <div style="display: flex; justify-content: center; margin-left: 10px;">
              <div style="display: flex; flex-direction: column; width: 100%;">
                <.form for={@email_form} phx-change="change-email-form" style="width: 100%">
                  <.input
                    field={@email_form[:email]}
                    type="text"
                    class="text-input-1"
                    placeholder="seu email"
                    autocomplete="email"
                    style="width: 100%"
                  />
                  <div style={if @email_form_is_empty, do: "opacity: 50%;"}>
                    <div style="display: flex; justify-content: center; margin-top: 50px;">
                      <a disabled={@email_form_is_empty} href="#top" phx-click="submit-email-form">
                        <img src="/svg/continuar.svg" />
                      </a>
                    </div>
                  </div>
                </.form>
                <div style="margin-left: auto;">
                  <div style="position: relative; bottom: 145px;">
                    <button
                      class="has-font-3"
                      style="text-decoration: underline; font-size: 20px;"
                      phx-click="checkout-as-guest"
                    >
                      voltar para login
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div :if={@current_user}>
            <div style="display: flex; justify-content: center; margin-top: 50px; margin-bottom: 150px;">
              <a
                phx-click="step"
                phx-value-step="2"
                style={if @cart_out_of_stock, do: "opacity: 50%"}
                disabled={@cart_out_of_stock}
                href="#top"
              >
                <img src="/svg/comprar.svg" />
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(%{step: 2} = assigns) do
    ~H"""
    <div
      class="has-font-3"
      style="margin-top: 50px; margin-bottom: 400px; margin-left: 10px; margin-right: 10px;"
    >
      <div style="display: flex; justify-content: center;">
        <div style="display: flex; flex-direction: column;">
          <div style="align-self: center; font-size: 46px; margin-bottom: 9px;">
            Endereço para entrega
          </div>
          <div style="align-self: center; font-size: 22px; margin-bottom: 55px;">
            preencha com o endereço para calcular o frete
          </div>
          <div style="margin-bottom: 19px; align-self: center;">
            <.form for={@name_form} phx-change="change-name-form">
              <.input
                field={@name_form[:name]}
                type="text"
                placeholder="nome"
                class="text-input-1"
                style="text-align: center; font-size: 28px; width: 300px;"
                autocomplete="name"
                phx-debounce="500"
              >
              </.input>
            </.form>
          </div>
          <div style="align-self: center; margin-bottom: 50px;">
            <.form
              id="address-form"
              for={@address_form}
              phx-change="change-address-form"
              phx-submit="submit-address-form"
            >
              <div style="display: flex; margin-bottom: 21px;">
                <.input
                  field={@address_form[:line1]}
                  type="text"
                  placeholder="endereço"
                  class="text-input-1"
                  style="width: 240px; margin-right: 10px; font-size: 28px;"
                  autocomplete="shipping address-line1"
                  phx-debounce="500"
                >
                </.input>
                <.input
                  field={@address_form[:line2]}
                  type="text"
                  placeholder="numero"
                  class="text-input-1"
                  style="width: 100px; font-size: 28px;"
                  autocomplete="shipping address-line2"
                  phx-debounce="500"
                >
                </.input>
              </div>
              <.input
                field={@address_form[:line3]}
                type="text"
                placeholder="complemento"
                class="text-input-1"
                style="width: 350px; font-size: 28px; margin-bottom: 21px;"
                autocomplete="shipping address-line3"
                phx-debounce="500"
              >
              </.input>
              <.input
                phx-change="change-postal-code"
                field={@address_form[:postal_code]}
                type="text"
                placeholder="cep"
                class="text-input-1"
                style="width: 350px; font-size: 28px; margin-bottom: 21px;"
                autocomplete="shipping postal-code"
                phx-debounce="500"
                onKeypress="window.hyphen();"
              >
              </.input>
              <div style="display: flex;">
                <.input
                  field={@address_form[:city]}
                  type="text"
                  placeholder="cidade"
                  class="text-input-1"
                  style="width: 170px; margin-right: 10px; font-size: 28px;"
                  autocomplete="shipping address-level2"
                  phx-debounce="500"
                >
                </.input>
                <.input
                  field={@address_form[:state]}
                  type="text"
                  placeholder="estado"
                  class="text-input-1"
                  style="width: 170px; font-size: 28px;"
                  autocomplete="shipping address-level1"
                  phx-debounce="500"
                >
                </.input>
              </div>
            </.form>
          </div>
          <div style="align-self: center; margin-bottom: 50px;">
            <.delivery_method_form
              options={@delivery_methods}
              selected={@delivery_method}
              error={@delivery_methods_error}
              waiting={@delivery_methods_waiting}
            />
          </div>
          <div style="display: flex; justify-content: center; ">
            <button
              type="submit"
              form="address-form"
              disabled={!(@name_form_valid && @address_form.source.valid?)}
              style={if !(@name_form_valid && @address_form.source.valid?), do: "opacity: 50%"}
            >
              <img src="/svg/continuar.svg" />
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
          verifique seu e-mail para receber seu recibo e atualizações
        </div>
        <div style="display: flex; justify-content: center; margin-top: 50px;">
          <div style="display: flex; flex-direction: column; width: 300px;">
            <img src="svg/yellow-ellipse.svg" />
            <div class="has-font-3" style="position: relative; bottom: 115px; font-size: 55px;">
              Successo!
            </div>
          </div>
        </div>
        <div style="font-size: 30px; margin-top: 10px; text-decoration: underline;">
          <.link navigate="/">
            Voltar para plazaaaaa
          </.link>
        </div>
      </div>
    </div>
    """
  end

  defp sign_in_or_continue_as_guest(%{current_user: nil} = assigns) do
    ~H"""
    <div style="display: flex; justify-content: right;">
      <div>
        <div style="font-size: 44px;">
          checkout
        </div>
        <div style="font-size: 22px;">
          coloque seu email para fazer login ou continue como convidado
        </div>
        <div>
          <PlazaWeb.Auth.Login.login_quick
            form={@login_form}
            redirect_url="/checkout"
            button_right={true}
            width="100%"
          />
        </div>
        <div>
          <div style="font-size: 36px;">
            checkout como convidado
          </div>
          <div style="font-size: 22px;">
            coloque apenas seu email
          </div>
          <div>
            <.form for={@email_form} phx-change="change-email-form" phx-submit="submit-email-form">
              <.input
                field={@email_form[:email]}
                type="text"
                class="text-input-1"
                style="width: 100%;"
                placeholder="seu email"
                autocomplete="email"
              />
              <div style="display: flex; width: 100%;">
                <div style="margin-left: auto;">
                  <div style={if @email_form_is_empty, do: "opacity: 50%;"}>
                    <button
                      disabled={@email_form_is_empty}
                      style="font-size: 32px; text-decoration: underline;"
                      class="has-font-3"
                    >
                      Continuar
                    </button>
                  </div>
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

    """
  end

  defp delivery_method_form(%{waiting: true} = assigns) do
    ~H"""
    <div style="text-align: center;">
      <div style="font-size: 28px;">
        . . .
      </div>
    </div>
    """
  end

  defp delivery_method_form(%{options: nil, error: false} = assigns) do
    ~H"""
    <div style="text-align: center;">
      <div style="font-size: 28px;">
        Opções de frete:
      </div>
      <div style="font-size: 22px; color: grey;">
        Aguardando CEP
      </div>
    </div>
    """
  end

  defp delivery_method_form(%{options: nil, error: true} = assigns) do
    ~H"""
    <div style="text-align: center;">
      <div style="font-size: 28px;">
        Opções de frete:
      </div>
      <div style="font-size: 22px; color: grey; text-decoration: underline;">
        CEP INCORRETO
      </div>
      <div style="font-size: 22px; color: grey;">
        Por favor revise os dados
      </div>
    </div>
    """
  end

  defp delivery_method_form(%{options: options, error: false, selected: selected} = assigns) do
    ~H"""
    <div style="text-align: center;">
      <div style="font-size: 28px; margin-bottom: 10px;">
        Opções de frete:
      </div>
      <div style="display: flex; justify-content: center;">
        <div>
          <button
            :for={option <- options}
            class="has-font-3"
            style="display: flex; font-size: 26px; margin-bottom: 10px;"
            phx-click="select-delivery-method"
            phx-value-id={option.id}
            phx-value-price={option.price}
            phx-value-name={option.name}
            phx-value-days={option.days}
          >
            <img
              src={
                if option.id == selected.id,
                  do: "/svg/yellow-circle.svg",
                  else: "/svg/white-circle.svg"
              }
              style="width: 30px; align-self: center;"
            />
            <div style="font-size: 24px; margin-left: 5px;">
              <%= "#{option.name} #{option.days} Dias Úteis R$#{(option.price / 100) |> Float.to_string() |> String.replace(".", ",")}" %>
            </div>
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp normalize_delivery_method(raw) do
    {price, _} = Float.parse(raw.value)
    price = (price * 100) |> Kernel.round()

    %{
      id: raw.delivery_method_id |> Integer.to_string(),
      price: price,
      name: raw.name,
      days: raw.business_days
    }
  end
end
