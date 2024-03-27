defmodule PlazaWeb.MyStoreLive do
  use PlazaWeb, :live_view

  require Logger

  alias Ecto.Changeset

  alias Plaza.Accounts
  alias Plaza.Accounts.Seller
  alias Plaza.Accounts.SellerForm
  alias Plaza.Accounts.Socials
  alias Plaza.Products
  alias PlazaWeb.ProductComponent

  alias ExAws.S3

  @local_storage_key "plaza-product-form"

  @aws_s3_region "us-west-2"
  @aws_s3_bucket "plaza-static-dev"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      case connected?(socket) do
        true ->
          user_id = socket.assigns.current_user.id
          seller = Accounts.get_seller_by_id(user_id)
          products = Products.list_products_by_user_id(user_id, 3)

          seller_form =
            to_form(
              SellerForm.changeset(
                %SellerForm{
                  user_id: user_id
                },
                %{}
              )
            )

          logo_upload =
            case seller do
              nil ->
                nil

              seller ->
                case seller.profile_photo_url do
                  nil -> nil
                  url -> %{new: false, url: url, name: "your-current-logo.foto"}
                end
            end

          socket =
            case products do
              [] ->
                socket
                |> push_event(
                  "read",
                  %{
                    key: @local_storage_key,
                    event: "read-product-form"
                  }
                )
                |> assign(product_buffer: nil)

              _ ->
                socket
            end

          socket =
            socket
            |> assign(header: :my_store)
            |> assign(seller: seller)
            |> assign(products: products)
            |> assign(all_products: false)
            |> assign(deleting_products: false)
            |> assign(delete_buffer: nil)
            |> assign(logo_upload: logo_upload)
            |> assign(seller_form: seller_form)
            |> assign(uuid: UUID.uuid1())
            |> assign(waiting: false)

        false ->
          socket
          |> assign(waiting: true)
      end

    {:ok, socket}
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

  def handle_event("all-products", _, socket) do
    products = Products.list_products_by_user_id(socket.assigns.current_user.id)

    socket =
      socket
      |> assign(products: products)
      |> assign(all_products: true)

    {:noreply, socket}
  end

  def handle_event("show-delete-button", _, socket) do
    socket =
      socket
      |> assign(deleting_products: true)

    {:noreply, socket}
  end

  def handle_event("hide-delete-button", _, socket) do
    socket =
      socket
      |> assign(deleting_products: false)

    {:noreply, socket}
  end

  def handle_event("add-product-to-delete-buffer", %{"product-id" => product_id}, socket) do
    socket =
      socket
      |> assign(delete_buffer: String.to_integer(product_id))

    {:noreply, socket}
  end

  def handle_event("remove-product-from-delete-buffer", _, socket) do
    socket =
      socket
      |> assign(delete_buffer: nil)

    {:noreply, socket}
  end

  def handle_event("delete-product", _, socket) do
    user_id = socket.assigns.current_user.id
    product_id = socket.assigns.delete_buffer
    product = Products.get_product!(product_id)
    Products.delete_product(product)

    products =
      case socket.assigns.all_products do
        true ->
          Products.list_products_by_user_id(user_id)

        false ->
          Products.list_products_by_user_id(user_id, 3)
      end

    socket =
      socket
      |> assign(products: products)
      |> assign(delete_buffer: nil)

    {:noreply, socket}
  end

  def handle_event("read-product-form", token_data, socket) when is_binary(token_data) do
    socket =
      case restore_from_token(token_data) do
        {:ok, nil} ->
          # do nothing with the previous state
          socket

        {:ok, restored} ->
          socket
          |> assign(:product_buffer, restored)

        {:error, reason} ->
          # We don't continue checking. Display error.
          # Clear the token so it doesn't keep showing an error.
          socket
          |> put_flash(:error, reason)
          |> clear_browser_storage()
      end

    {:noreply, socket}
  end

  def handle_event("read-product-form", _token_data, socket) do
    Logger.debug("No (valid) prodouct-form to restore")
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

  def handle_event("product-href", %{"product-id" => product_id}, socket) do
    params = %{"product-id" => product_id}
    url = URI.encode_query(params)
    {:noreply, push_navigate(socket, to: "/product?#{url}")}
  end

  def handle_event("change-seller-form", %{"seller_form" => attrs}, socket) do
    seller_form =
      SellerForm.changeset(
        socket.assigns.seller_form.data,
        attrs
      )
      |> Map.put(:action, :insert)
      |> to_form()

    socket =
      socket
      |> assign(seller_form: seller_form)
      |> assign(uuid: UUID.uuid1())

    {:noreply, socket}
  end

  def handle_event("logo-upload-change", file_name, socket) do
    socket =
      socket
      |> assign(logo_upload: %{new: true, url: file_name, name: "your-new-logo.foto"})

    {:noreply, socket}
  end

  def handle_event("logo-upload-cancel", file_name, socket) do
    socket =
      socket
      |> assign(logo_upload: nil)
      |> push_event("logo-upload-cancel", %{})

    {:noreply, socket}
  end

  def handle_event("submit-seller-form", %{"seller_form" => attrs}, socket) do
    Task.async(fn ->
      changes =
        SellerForm.changeset(
          socket.assigns.seller_form.data,
          attrs
        )
        |> Changeset.apply_action(:update)

      case changes do
        {:error, changeset} ->
          {:invalid_changes, changeset |> to_form}

        {:ok, seller_form} ->
          seller = SellerForm.to_seller(seller_form)

          case socket.assigns.logo_upload do
            nil ->
              {:valid_changes, seller}

            logo_upload ->
              case logo_upload do
                %{new: true} ->
                  {:upload_logo, seller}

                _ ->
                  {:valid_changes, seller}
              end
          end
      end
    end)

    socket =
      socket
      |> assign(waiting: true)

    {:noreply, socket}
  end

  def handle_event("s3-upload-complete", "logo", socket) do
    seller = socket.assigns.seller
    url = "https://#{@aws_s3_bucket}.s3.#{@aws_s3_region}.amazonaws.com"
    file_name = URI.encode(socket.assigns.logo_upload.url)
    file_name = "#{url}/#{file_name}"
    seller = %{seller | profile_photo_url: file_name}

    socket =
      create_or_update_seller(
        socket,
        seller
      )

    {:noreply, socket}
  end

  def handle_event("edit-seller", _params, socket) do
    seller = socket.assigns.seller

    {socket, logo_upload} =
      case seller.profile_photo_url do
        nil ->
          {socket, nil}

        s3_url ->
          socket =
            socket
            |> push_event(
              "plaza-logo-display-s3-url",
              %{url: s3_url}
            )

          {socket, %{new: false, url: s3_url, name: "your-current-logo.foto"}}
      end

    socket =
      socket
      |> assign(
        seller_form:
          to_form(
            SellerForm.changeset(
              SellerForm.from_seller(seller),
              %{}
            )
          )
      )
      |> assign(logo_upload: logo_upload)
      |> assign(uuid: UUID.uuid1())
      |> assign(step: "edit-seller")

    {:noreply, socket}
  end

  def handle_event("cancel-edit-seller", _params, socket) do
    socket =
      socket
      |> assign(step: nil)

    {:noreply, socket}
  end

  def handle_event("stripe-link-account", _params, socket) do
    Task.async(fn ->
      {:ok, %Stripe.Account{id: stripe_id}} =
        Stripe.Account.create(%{
          type: :express,
          capabilities: %{
            card_payments: %{
              requested: true
            },
            transfers: %{
              requested: true
            }
          }
        })

      {:ok, %Stripe.AccountLink{url: stripe_account_link_url}} =
        Stripe.AccountLink.create(%{
          account: stripe_id,
          refresh_url:
            "#{Application.get_env(:plaza, :app_url)}/my-store?stripe-setup-refresh=#{stripe_id}",
          return_url:
            "#{Application.get_env(:plaza, :app_url)}/my-store?stripe-setup-return=#{stripe_id}",
          type: :account_onboarding
        })

      {:stripe_link_account, stripe_account_link_url}
    end)

    socket =
      socket
      |> assign(waiting: true)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"stripe-setup-refresh" => stripe_id}, _uri, socket) do
    socket =
      case connected?(socket) do
        true ->
          {:ok, %Stripe.AccountLink{url: stripe_account_link_url}} =
            Stripe.AccountLink.create(%{
              account: stripe_id,
              refresh_url:
                "#{Application.get_env(:plaza, :app_url)}/my-store?stripe-setup-refresh=#{stripe_id}",
              return_url:
                "#{Application.get_env(:plaza, :app_url)}/my-store?stripe-setup-return=#{stripe_id}",
              type: :account_onboarding
            })

          socket
          |> redirect(external: stripe_account_link_url)

        false ->
          socket
      end

    {:noreply, socket}
  end

  def handle_params(%{"stripe-setup-return" => stripe_id}, _uri, socket) do
    socket =
      case connected?(socket) do
        true ->
          ## give time for stripe to post new status
          Process.sleep(5000)

          {:ok,
           %Stripe.Account{
             capabilities: capabilities
           } = stripe_account} = Stripe.Account.retrieve(stripe_id)

          seller = Accounts.get_seller_by_id(socket.assigns.current_user.id)
          products = socket.assigns.products

          {seller, products} =
            case capabilities do
              %{card_payments: "active", transfers: "active"} ->
                seller = %{seller | stripe_id: stripe_id}
                {:ok, seller} = Accounts.update_seller(seller)

                products =
                  case products do
                    [product] ->
                      {:ok, product} = Products.activate_product(product)
                      [product]

                    [] ->
                      []
                  end

                {seller, products}

              _ ->
                {seller, products}
            end

          socket
          |> assign(seller: seller)
          |> assign(products: products)

        false ->
          socket
      end

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({ref, {:stripe_link_account, url}}, socket) do
    Process.demonitor(ref, [:flush])

    socket =
      socket
      |> redirect(external: url)

    {:noreply, socket}
  end

  def handle_info({ref, {:invalid_changes, seller_form}}, socket) do
    Process.demonitor(ref, [:flush])

    socket =
      socket
      |> assign(seller_form: seller_form)
      |> assign(waiting: false)

    {:noreply, socket}
  end

  def handle_info({ref, {:valid_changes, seller}}, socket) do
    Process.demonitor(ref, [:flush])

    socket =
      create_or_update_seller(
        socket,
        seller
      )

    {:noreply, socket}
  end

  def handle_info({ref, {:upload_logo, seller}}, socket) do
    Process.demonitor(ref, [:flush])

    url = "https://#{@aws_s3_bucket}.s3-#{@aws_s3_region}.amazonaws.com"

    config = %{
      region: @aws_s3_region,
      access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID_PLAZA"),
      secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY_PLAZA")
    }

    {:ok, fields} =
      PlazaWeb.S3UrlPresign.sign_form_upload(
        config,
        @aws_s3_bucket,
        key: socket.assigns.logo_upload.url,
        content_type: "image/png",
        max_file_size: 10_000_000,
        expires_in: :timer.hours(1)
      )

    socket =
      socket
      |> assign(seller: seller)
      |> push_event("upload", %{
        url: url,
        fields: fields,
        side: "logo"
      })

    {:noreply, socket}
  end

  defp create_or_update_seller(socket, seller) do
    socket =
      case socket.assigns.seller do
        nil ->
          create_seller(socket, seller)

        %{id: nil} ->
          create_seller(socket, seller)

        _ ->
          {:ok, seller} = Accounts.update_seller(seller)

          socket
          |> assign(seller: seller)
          |> assign(step: nil)
      end

    socket
    |> assign(waiting: false)
  end

  defp create_seller(socket, seller) do
    case Accounts.create_seller(seller) do
      {:ok, seller} ->
        products =
          case socket.assigns.product_buffer do
            nil ->
              []

            product ->
              product = %{
                product
                | user_id: seller.user_id,
                  user_name: seller.user_name
              }

              {:ok, product} = Products.create_product(product)
              [product]
          end

        socket
        |> assign(seller: seller)
        |> assign(products: products)

      {:error, changeset} ->
        socket
        |> assign(seller_form: changeset |> to_form)
    end
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

  def render(%{seller: nil, product_buffer: nil} = assigns) do
    ~H"""
    <div class="is-my-store-page-desktop">
      <div class="has-font-3" style="margin-top: 100px; margin-bottom: 250px; font-size: 34px;">
        <div style="display: flex; justify-content: center; margin-bottom: 100px;">
          <.link navigate="/upload" style="text-decoration: underline;">
            Vá fazer upload do seu primeiro produto
          </.link>
        </div>
        <div style="display: flex; justify-content: center;">
          Ou preencha para criar seu perfil de loja
        </div>
        <div style="position: relative; top: 50px;">
          <.seller_form
            seller_form={@seller_form}
            logo_upload={@logo_upload}
            seller={@seller}
            uuid={@uuid}
          />
        </div>
      </div>
    </div>
    <div class="is-my-store-page-mobile">
      <PlazaWeb.CustomComponents.how_it_works_seller_mobile />
    </div>
    """
  end

  def render(%{seller: nil, product_buffer: product} = assigns) do
    ~H"""
    <div class="is-my-store-page-desktop">
      <div class="has-font-3" style="font-size: 34px; margin-top: 100px; margin-bottom: 250px;">
        <div style="display: flex; justify-content: center;">
          <div>
            <div style="margin-bottom: 50px;">
              Você enviou seu primeiro produto
            </div>
            <div style="display: flex; justify-content: center;">
              <ProductComponent.product
                product={product}
                meta={false}
                disabled={true}
                style="width: 250px;"
              />
            </div>
          </div>
        </div>
        <div style="display: flex; justify-content: center; margin-bottom: 50px;">
          Crie sua loja antes que o produto seja lançado
        </div>
        <div>
          <.seller_form
            seller_form={@seller_form}
            logo_upload={@logo_upload}
            seller={@seller}
            uuid={@uuid}
          />
        </div>
      </div>
    </div>
    <div class="is-my-store-page-mobile">
      <PlazaWeb.CustomComponents.how_it_works_seller_mobile />
    </div>
    """
  end

  def render(%{step: "edit-seller"} = assigns) do
    ~H"""
    <div class="is-my-store-page-desktop">
      <div style="margin-top: 100px; margin-bottom: 150px;">
        <div style="display: flex; flex-direction: column;">
          <.seller_form
            seller_form={@seller_form}
            logo_upload={@logo_upload}
            seller={@seller}
            uuid={@uuid}
          />
          <div style="display: flex; justify-content: center; margin-top: 50px;">
            <button
              phx-click="cancel-edit-seller"
              class="has-font-3"
              style="border-bottom: 2px solid black; width: 50px; font-size: 32px;"
            >
              cancelar
            </button>
          </div>
        </div>
      </div>
    </div>
    <div class="is-my-store-page-mobile">
      <PlazaWeb.CustomComponents.how_it_works_seller_mobile />
    </div>
    """
  end

  def render(%{seller: %Seller{stripe_id: nil}, products: []} = assigns) do
    ~H"""
    <div class="is-my-store-page-desktop">
      <div style="display: flex; justify-content: center;">
        <div style="display: flex; margin-bottom: 50px; max-width: 1687px; width: 100%; margin-right: 10px;">
          <.left seller={@seller} />
          <div style="margin-left: 150px; margin-top: 100px;">
            <div class="has-font-3" style="font-size: 34px;">
              <div style="display: flex; justify-content: center;">
                <div style="text-align: center;">
                  <div style="margin-bottom: 20px;">
                    Ok, você criou sua loja
                  </div>
                  <div style="margin-bottom: 50px;">
                    Vá fazer upload do seu primeiro produto
                    <div style="text-decoration: underline;">
                      <.link navigate="/upload">
                        upload
                      </.link>
                    </div>
                  </div>
                </div>
                <div style="max-width: 500px;">
                  Ou vincule suas informações bancárias ao stripe para que você possa receber o pagamento por cada venda.
                  Você precisará fazer isso antes de sua loja entrar no ar.
                  <div style="text-decoration: underline;">
                    <button phx-click="stripe-link-account">Crie uma conta stripe</button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="is-my-store-page-mobile">
      <PlazaWeb.CustomComponents.how_it_works_seller_mobile />
    </div>
    """
  end

  def render(%{seller: %Seller{stripe_id: nil}, products: [product]} = assigns) do
    ~H"""
    <div class="is-my-store-page-desktop">
      <div style="display: flex; justify-content: center;">
        <div style="display: flex; margin-bottom: 50px; max-width: 1687px; width: 100%; margin-right: 10px;">
          <.left seller={@seller} />
          <div style="margin-top: 100px; width: 100%;">
            <div class="has-font-3" style="font-size: 34px;">
              <div style="display: flex; justify-content: center;">
                <div style="text-align: center; margin-right: 20px;">
                  <div style="margin-bottom: 20px;">
                    Ok, você criou sua loja
                  </div>
                  <div>
                    <div style="margin-bottom: 50px;">
                      E você enviou seu primeiro produto
                    </div>
                    <div style="display: flex; justify-content: center;">
                      <ProductComponent.product
                        product={product}
                        meta={false}
                        disabled={true}
                        style="width: 250px;"
                      />
                    </div>
                  </div>
                  <div style="border: 1px dotted black; text-align: center; padding-left: 10px; padding-right: 10px; max-width: 500px;">
                    Você só precisa vincular suas informações bancárias ao stripe para poder receber o pagamento por cada venda.
                    <div style="margin-top: 25px; margin-bottom: 25px;">
                      <button
                        class="has-font-3"
                        style="text-decoration: underline;"
                        phx-click="stripe-link-account"
                      >
                        Crie uma conta stripe
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="is-my-store-page-mobile">
      <PlazaWeb.CustomComponents.how_it_works_seller_mobile />
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="is-my-store-page-desktop">
      <div style="display: flex; justify-content: center;">
        <div style="display: flex; max-width: 1687px; width: 100%; margin-right: 10px;">
          <.left seller={@seller} />
          <.right
            products={@products}
            all_products={@all_products}
            deleting_products={@deleting_products}
            delete_buffer={@delete_buffer}
          />
        </div>
      </div>
    </div>
    <div class="is-my-store-page-mobile">
      <PlazaWeb.CustomComponents.how_it_works_seller_mobile />
    </div>
    """
  end

  defp left(assigns) do
    seller = assigns.seller

    description =
      case seller.description do
        nil ->
          "Breve descrição do artista. Maximo 140 caracteres."

        nn ->
          nn
      end

    location =
      case seller.location do
        nil ->
          "Localização do artista"

        nn ->
          nn
      end

    website =
      case seller.website do
        nil ->
          {:default, "Website"}

        nn ->
          %{url: nn, name: "Website"}
      end

    instagram =
      case seller.socials.instagram do
        nil ->
          {:default, "Instagram"}

        nn ->
          %{url: nn, name: "Instagram"}
      end

    twitter =
      case seller.socials.twitter do
        nil ->
          {:default, "Twitter"}

        nn ->
          %{url: nn, name: "Twitter"}
      end

    soundcloud =
      case seller.socials.soundcloud do
        nil ->
          {:default, "Soundcloud"}

        nn ->
          %{url: nn, name: "Soundcloud"}
      end

    urls = [
      website,
      instagram,
      twitter,
      soundcloud
    ]

    assigns =
      assigns
      |> assign(user_description: description)
      |> assign(user_location: location)
      |> assign(user_urls: urls)

    ~H"""
    <div class="has-font-3">
      <div style="width: 395px; height: 377px; overflow: hidden; border-bottom: 1px solid grey;">
        <div
          :if={!@seller.profile_photo_url}
          style="display: flex; justify-content: center; height: 100%; text-decoration: underline; text-align: center; font-size: 22px;"
        >
          <div style="display: flex; flex-direction: column; justify-content: center;">
            <div>
              Upload
            </div>
            <div>
              Logo/Foto de Perfil
            </div>
          </div>
        </div>
        <img
          :if={@seller.profile_photo_url}
          src={@seller.profile_photo_url}
          style="min-width: 100%; min-height: 100%;"
        />
      </div>
      <div style="display: flex; flex-direction: column;">
        <div style="margin-left: 60px; margin-top: 22px;">
          <div style="text-decoration: underline; font-size: 32px; margin-bottom: 22px;">
            <%= @seller.user_name %>
          </div>
          <div style="font-size: 32px; line-height: 30px; width: 267px; margin-bottom: 15px;">
            <%= @user_description %>
          </div>
          <div class="has-dark-gray-text" style="margin-bottom: 45px; font-size: 28px;">
            <%= @user_location %>
          </div>
          <div
            :for={url <- @user_urls}
            style="text-decoration: underline; font-size: 30px; line-height: 39px;"
          >
            <.url_or url={url} />
          </div>
          <div style="margin-top: 43px; height: 30px; width: 33px; border-top: none; border-left: none; border-right: none; border-bottom: 2px solid grey; color: grey;">
            <button phx-click="edit-seller" class="has-font-3" style="font-size: 24px;">
              Editar
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp url_or(%{url: %{url: url, name: _}} = assigns) do
    href =
      case String.starts_with?(url, "https://") do
        true ->
          url

        false ->
          case String.starts_with?(url, "http://") do
            true ->
              url

            false ->
              "http://#{url}"
          end
      end

    assigns =
      assigns
      |> assign(href: href)

    ~H"""
    <a href={@href} target="_blank">
      <%= @url.name %>
    </a>
    """
  end

  defp url_or(assigns) do
    ~H"""

    """
  end

  defp right(assigns) do
    ~H"""
    <div style="padding-top: 45px; width: 100%; border-left: 1px solid #707070;">
      <div style="margin-left: 167px; margin-bottom: 45px; display: flex;">
        <.link
          navigate="/upload"
          style="text-decoration: underline; font-size: 32px; margin-right: 15px;"
          class="has-font-3"
        >
          Criar mais produtos
        </.link>
        <button
          :if={!@deleting_products}
          style="text-decoration: underline; font-size: 32px; color: grey;"
          class="has-font-3"
          phx-click="show-delete-button"
        >
          Excluir produtos
        </button>
        <button
          :if={@deleting_products}
          style="text-decoration: underline; font-size: 32px; color: #F00;"
          class="has-font-3"
          phx-click="hide-delete-button"
        >
          Parar de excluir
        </button>
      </div>
      <div style="margin-left: 75px; margin-bottom: 150px">
        <div class="columns is-multiline is-7">
          <%= for product <- @products do %>
            <div
              class="column is-one-third-widescreen is-half-desktop is-12-tablet"
              style="position: relative;"
            >
              <div>
                <ProductComponent.product product={product} meta={true} disabled={false} />
              </div>
              <div
                :if={@deleting_products}
                style="position: absolute; height: 100%; width: 100%; left: 0; top: 0;"
              >
                <div style="margin-left: 25px; margin-top: 10px;">
                  <button
                    phx-click="add-product-to-delete-buffer"
                    phx-value-product-id={product.id}
                    style="text-decoration: underline; font-size: 32px;"
                    class="has-font-3"
                  >
                    Deletar
                  </button>
                </div>
                <div
                  :if={@delete_buffer == product.id}
                  style="display: flex; justify-content: center; margin-top: 34px;"
                  class="has-font-3"
                >
                  <div style="width: 70%; aspect-ratio: 9/10; background-color: #F8FC5F; border: 1px solid black; display: flex; justify-content: center;">
                    <div style="display: flex; flex-direction: column; justify-content: center;">
                      <div style="text-align: center; font-size: 32px; margin-bottom: 36px; text-decoration: underline;">
                        Tem certeza que deseja
                        deletar seu produto?
                      </div>
                      <div style="display: flex; justify-content: center;">
                        <button
                          phx-click="remove-product-from-delete-buffer"
                          style="font-size: 32px; text-decoration: underline; margin-right: 44px;"
                          class="has-font-3"
                        >
                          Cancelar
                        </button>
                        <button
                          phx-click="delete-product"
                          style="font-size: 32px; text-decoration: underline;"
                          class="has-font-3"
                        >
                          Sim
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
      <div :if={!@all_products} style="display: flex; justify-content: center; margin-bottom: 200px;">
        <button
          class="has-font-3"
          style="text-decoration: underline; font-size: 28px;"
          phx-click="all-products"
        >
          Ver todos os meus produtos
        </button>
      </div>
    </div>
    """
  end

  attr :seller_form, :map, required: true
  attr :logo_upload, :map, required: true
  attr :seller, :map, required: true
  attr :uuid, :string, required: true

  defp seller_form(assigns) do
    ~H"""
    <div style="display: flex; justify-content: center;">
      <div>
        <form>
          <div :if={!@logo_upload}>
            <label
              class="has-font-3 is-size-4"
              style="width: 312px; height: 300px; border: 1px solid black; display: flex; justify-content: center; align-items: center;"
            >
              <input
                id="plaza-logo-input"
                phx-hook="LogoFileReader"
                type="file"
                accept=".png"
                multiple={false}
                style="display: none;"
              />
              <div style="text-align: center; text-decoration: underline; font-size: 24px;">
                Upload
                <div>
                  Logo/Foto de Perfil
                </div>
              </div>
            </label>
          </div>
          <div
            :if={@logo_upload}
            id={"plaza-logo-display-hook-#{@uuid}"}
            phx-hook="LogoDisplay"
            style="position: relative; left: 5px;"
          >
            <div style="width: 312px; height: 300px; overflow: hidden; border: 1px solid black;">
              <img id="plaza-logo-display" style="min-width: 100%; min-height: 100%;" />
            </div>
            <div style="display: inline-block; width: 270px; font-size: 24px; color: gray;">
              <%= @logo_upload.name %>
            </div>
            <div style="display: inline-block;">
              <button type="button" phx-click="logo-upload-cancel">
                &times;
              </button>
            </div>
          </div>
        </form>
      </div>
      <div>
        <div style="margin-left: 50px;">
          <.form
            for={@seller_form}
            phx-change="change-seller-form"
            phx-submit="submit-seller-form"
            style="width: 450px;"
          >
            <.input
              field={@seller_form[:user_name]}
              type="text"
              placeholder="username / nome da loja *"
              class="text-input-1"
              style="width: 100%; text-align: center;"
              phx-debounce="500"
            >
            </.input>
            <.input
              field={@seller_form[:website]}
              type="text"
              placeholder="website"
              class="text-input-1"
              style="width: 100%; text-align: center;"
              phx-debounce="500"
            >
            </.input>
            <.input
              field={@seller_form[:instagram]}
              type="text"
              placeholder="instagram"
              class="text-input-1"
              style="width: 100%; text-align: center;"
              phx-debounce="500"
            >
            </.input>
            <.input
              field={@seller_form[:twitter]}
              type="text"
              placeholder="twitter"
              class="text-input-1"
              style="width: 100%; text-align: center;"
              phx-debounce="500"
            >
            </.input>
            <.input
              field={@seller_form[:soundcloud]}
              type="text"
              placeholder="soundcloud"
              class="text-input-1"
              style="width: 100%; text-align: center;"
              phx-debounce="500"
            >
            </.input>
            <div style="position: relative; right: 357px; top: 50px;">
              <div>
                <.input
                  field={@seller_form[:description]}
                  type="textarea"
                  placeholder="Breve descrição da loja/artista"
                  phx-debounce="500"
                  maxlength="140"
                  style="width: 500px; height: 100px; padding-left: 10px;"
                >
                </.input>
              </div>
              <div>
                <.input
                  field={@seller_form[:location]}
                  type="text"
                  placeholder="Localização"
                  class="text-input-1"
                  phx-debounce="500"
                >
                </.input>
              </div>
            </div>
            <div style="margin-left: 200px;">
              <button>
                <img src="/svg/yellow-ellipse.svg" />
                <div class="has-font-3" style="position: relative; bottom: 79px; font-size: 36px;">
                  <%= if !@seller, do: "Continuar", else: "Editar" %>
                </div>
              </button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
