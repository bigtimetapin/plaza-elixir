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

  ## @site "http://localhost:4000"
  @site "https://plazaaaaa-solitary-snowflake-7144-summer-wave-9195.fly.dev"
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
          refresh_url: "#{@site}/my-store?stripe-setup-refresh=#{stripe_id}",
          return_url: "#{@site}/my-store?stripe-setup-return=#{stripe_id}",
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
              refresh_url: "#{@site}/my-store?stripe-setup-refresh=#{stripe_id}",
              return_url: "#{@site}/my-store?stripe-setup-return=#{stripe_id}",
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
    <div style="margin-top: 200px; display: flex; justify-content: center;">
      <img src="gif/loading.gif" />
    </div>
    """
  end

  def render(%{seller: nil, product_buffer: nil} = assigns) do
    ~H"""
    <div class="has-font-3" style="margin-top: 150px; margin-bottom: 250px; font-size: 34px;">
      <div style="display: flex; justify-content: center; margin-bottom: 100px;">
        <.link navigate="/upload" style="text-decoration: underline;">
          go upload some stuff
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
    """
  end

  def render(%{seller: nil, product_buffer: product} = assigns) do
    ~H"""
    <div class="has-font-3" style="font-size: 34px; margin-top: 150px; margin-bottom: 250px;">
      <div style="display: flex; justify-content: center;">
        <div>
          you've uploaded your first product
          <div>
            <ProductComponent.product product={product} meta={false} disabled={true} />
          </div>
        </div>
      </div>
      <div style="display: flex; justify-content: center; margin-top: 100px; margin-bottom: 50px;">
        create your store before the product goes live
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
    """
  end

  def render(%{step: "edit-seller"} = assigns) do
    ~H"""
    <div style="margin-top: 150px; margin-bottom: 150px;">
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
            cancel
          </button>
        </div>
      </div>
    </div>
    """
  end

  def render(%{seller: %Seller{stripe_id: nil}, products: []} = assigns) do
    ~H"""
    <div style="display: flex; margin-bottom: 50px;">
      <.left seller={@seller} />
      <div style="margin-left: 150px; margin-top: 150px;">
        <div class="has-font-3" style="font-size: 34px;">
          <div style="display: flex; justify-content: center;">
            <div style="text-align: center;">
              <div style="margin-bottom: 50px;">
                Ok you've created your seller (loja) profile
              </div>
              <div style="margin-bottom: 50px;">
                Go upload your first product
                <div style="text-decoration: underline;">
                  <.link navigate="/upload">
                    upload
                  </.link>
                </div>
              </div>
              <div style="width: 785px;">
                Or link your bank info with stripe so you can get paid for every sale.
                You'll need to do this before your products go live.
                <div style="text-decoration: underline;">
                  <button phx-click="stripe-link-account">link stripe account</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(%{seller: %Seller{stripe_id: nil}, products: [product]} = assigns) do
    ~H"""
    <div style="display: flex; margin-bottom: 50px;">
      <.left seller={@seller} />
      <div style="margin-left: 150px; margin-top: 150px;">
        <div class="has-font-3" style="font-size: 34px;">
          <div style="text-align: center;">
            <div style="margin-bottom: 50px;">
              Ok you've created your seller (loja) profile
            </div>
            <div style="margin-bottom: 50px;">
              and you've uploaded your first product
              <div>
                <ProductComponent.product product={product} meta={false} disabled={true} />
              </div>
            </div>
          </div>
          <div style="border: 1px dotted black; text-align: center;">
            You just need to link your bank info with stripe so you can get paid for every sale.
            <div style="text-decoration: underline; margin-top: 50px;">
              <button phx-click="stripe-link-account">link stripe account</button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div style="display: flex;">
      <.left seller={@seller} />
      <.right products={@products} all_products={@all_products} />
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
          {:url, nn}
      end

    instagram =
      case seller.socials.instagram do
        nil ->
          {:default, "Instagram"}

        nn ->
          {:url, nn}
      end

    twitter =
      case seller.socials.twitter do
        nil ->
          {:default, "Twitter"}

        nn ->
          {:url, nn}
      end

    soundcloud =
      case seller.socials.soundcloud do
        nil ->
          {:default, "Soundcloud"}

        nn ->
          {:url, nn}
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
    <div class="has-font-3" style="position: relative; top: 50px;">
      <div style="width: 377px; height: 377px; overflow: hidden;">
        <div :if={!@seller.profile_photo_url} style="justify-content: center;">
          <div>
            Upload
          </div>
          <div>
            Logo/Foto de Perfil
          </div>
        </div>
        <img
          :if={@seller.profile_photo_url}
          src={@seller.profile_photo_url}
          style="min-width: 100%; min-height: 100%;"
        />
      </div>
      <div style="display: flex; flex-direction: column;">
        <div style="margin-left: auto; padding-top: 10px; width: 316px; height: 600px;">
          <div class="is-size-6 mb-small" style="text-decoration: underline;">
            <%= @seller.user_name %>
          </div>
          <div class="is-size-6 mb-xsmall" style="line-height: 30px; width: 267px;">
            <%= @user_description %>
          </div>
          <div class="is-size-6 mb-small has-dark-gray-text">
            <%= @user_location %>
          </div>
          <div :for={url <- @user_urls} class="is-size-6" style="text-decoration: underline;">
            <.url_or url={url} />
          </div>
          <div style="margin-top: 50px; height: 30px; width: 33px; border-top: none; border-left: none; border-right: none; border-bottom: 2px solid grey; color: grey;">
            <button phx-click="edit-seller" class="has-font-3" style="font-size: 24px;">
              Editar
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp url_or(%{url: {:url, url}} = assigns) do
    {url, href} =
      case String.starts_with?(url, "https://") do
        true ->
          {String.replace_prefix(url, "https://", ""), url}

        false ->
          case String.starts_with?(url, "http://") do
            true ->
              href = String.replace_prefix(url, "http://", "https://")
              {href |> String.replace_prefix("https://", ""), href}

            false ->
              {url, "https://#{url}"}
          end
      end

    assigns =
      assigns
      |> assign(url: url)
      |> assign(href: href)

    ~H"""
    <a href={@href} target="_blank">
      <%= @url %>
    </a>
    """
  end

  defp url_or(assigns) do
    ~H"""

    """
  end

  defp right(assigns) do
    ~H"""
    <div style="padding-top: 150px; width: 100%; border-left: 1px solid #707070;">
      <div style="margin-left: 100px; margin-bottom: 50px;">
        <.link navigate="/upload" style="text-decoration: underline;" class="has-font-3 is-size-6">
          upload more stuff
        </.link>
      </div>
      <div style="margin-left: 75px; margin-right: 75px; margin-bottom: 200px">
        <ProductComponent.products3 products={@products} />
      </div>
      <div :if={!@all_products} style="display: flex; justify-content: center; margin-bottom: 100px;">
        <button
          class="has-font-3"
          style="text-decoration: underline; font-size: 28px;"
          phx-click="all-products"
        >
          Ver todos os produtos
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
          <.form for={@seller_form} phx-change="change-seller-form" phx-submit="submit-seller-form">
            <.input
              field={@seller_form[:user_name]}
              type="text"
              placeholder="username / nome da loja *"
              class="text-input-1"
              phx-debounce="500"
            >
            </.input>
            <.input
              field={@seller_form[:website]}
              type="text"
              placeholder="website"
              class="text-input-1"
              phx-debounce="500"
            >
            </.input>
            <.input
              field={@seller_form[:instagram]}
              type="text"
              placeholder="instagram"
              class="text-input-1"
              phx-debounce="500"
            >
            </.input>
            <.input
              field={@seller_form[:twitter]}
              type="text"
              placeholder="twitter"
              class="text-input-1"
              phx-debounce="500"
            >
            </.input>
            <.input
              field={@seller_form[:soundcloud]}
              type="text"
              placeholder="soundcloud"
              class="text-input-1"
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
                  style="width: 500px; height: 100px;"
                >
                </.input>
              </div>
              <div>
                <.input
                  field={@seller_form[:location]}
                  type="text"
                  placeholder="Localização"
                  class="text-input-2"
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
