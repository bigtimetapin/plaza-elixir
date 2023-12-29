defmodule PlazaWeb.CheckoutLive do
  use PlazaWeb, :live_view

  require Logger

  alias Plaza.Accounts
  alias Plaza.Accounts.Address

  @site "http://localhost:4000"
  ## @site "https://plazaaaaa-solitary-snowflake-7144-summer-wave-9195.fly.dev"

  @local_storage_key "plaza-checkout-cart"

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
      |> assign(cart_total_amount: 0)
      |> assign(header: :checkout)
      |> assign(step: 1)

    {:ok, socket}
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

    cart_total_amount =
      List.foldl(cart, 0, fn item, acc -> item.product.price * item.quantity + acc end)

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

  def handle_event("step", %{"step" => "2"}, socket) do
    socket =
      socket
      |> assign(step: 2)

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
              <div style="display: flex; font-size: 22px; margin-top: 5px;">
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
      <button phx-click="step" phx-value-step="2">
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
    <div
      class="has-font-3"
      style="margin-top: 150px; margin-bottom: 150px; display: flex; justify-content: center;"
    >
      <div>
        here
      </div>
    </div>
    """
  end
end
