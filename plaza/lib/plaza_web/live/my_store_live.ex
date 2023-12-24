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
  @site "https://plazaaaaa.fly.dev"
  @local_storage_key "plaza-product-form"

  @aws_s3_region "us-west-2"
  @aws_s3_bucket "plaza-static-dev"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      case connected?(socket) do
        true ->
          user_id = socket.assigns.current_user.id
          IO.inspect(user_id)
          seller = Accounts.get_seller_by_id(user_id)
          IO.inspect(seller)
          products = Products.list_products_by_user_id(user_id, 3)
          IO.inspect(products)

          seller_form =
            to_form(
              SellerForm.changeset(
                %SellerForm{
                  user_id: user_id
                },
                %{}
              )
            )

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
            |> assign(local_logo_upload: %{})
            |> allow_upload(:logo,
              accept: ~w(.png .jpg .jpeg .svg .gif),
              max_entries: 1,
              auto_upload: true,
              progress: &handle_progress/3
            )
            |> assign(seller_form: seller_form)
            |> assign(waiting: false)

        false ->
          socket
          |> assign(waiting: true)
      end

    {:ok, socket}
  end

  defp handle_progress(:logo, entry, socket) do
    socket =
      if entry.done? do
        {local_url, file_name} =
          consume_uploaded_entry(socket, entry, fn %{path: path} ->
            unique_file_name =
              "#{entry.uuid}-#{entry.client_name}"
              |> String.replace(" ", "")

            dest =
              Path.join([
                :code.priv_dir(:plaza),
                "static",
                "uploads",
                unique_file_name
              ])

            File.cp!(path, dest)
            {:ok, {"uploads/#{unique_file_name}", entry.client_name}}
          end)

        socket =
          socket
          |> assign(
            :local_logo_upload,
            %{
              url: local_url,
              file_name: file_name
            }
          )
      else
        socket
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("read-product-form", token_data, socket) when is_binary(token_data) do
    socket =
      case restore_from_token(token_data) do
        {:ok, nil} ->
          IO.inspect("nothing")
          # do nothing with the previous state
          socket

        {:ok, restored} ->
          IO.inspect(restored)

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
    %{
      "instagram" => instagram,
      "soundcloud" => soundcloud,
      "twitter" => twitter,
      "user_name" => user_name,
      "website" => website
    } = attrs

    seller_form = socket.assigns.seller_form
    seller_form_data = seller_form.data

    seller_form_data = %{
      seller_form_data
      | user_name: user_name,
        website: website,
        instagram: instagram,
        soundcloud: soundcloud,
        twitter: twitter
    }

    seller_form = %{seller_form | data: seller_form_data}
    IO.inspect(seller_form)

    socket =
      socket
      |> assign(seller_form: seller_form)

    {:noreply, socket}
  end

  def handle_event("change-seller-logo", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("logo-upload-cancel", _params, socket) do
    socket =
      socket
      |> assign(local_logo_upload: %{})

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

      IO.inspect(changes)

      case changes do
        {:error, changeset} ->
          {:invalid_changes, changeset |> to_form}

        {:ok, seller_form} ->
          seller = SellerForm.to_seller(seller_form)
          IO.inspect(seller)

          case Map.get(socket.assigns.local_logo_upload, :url) do
            nil ->
              {:valid_changes, seller}

            url ->
              case String.starts_with?(url, "https") do
                true ->
                  {:valid_changes, seller}

                false ->
                  s3_url = publish_s3(url)
                  {:logo_uploaded, s3_url, seller}
              end
          end
      end
    end)

    socket =
      socket
      |> assign(waiting: true)

    {:noreply, socket}
  end

  defp publish_s3(local_url) do
    src =
      Path.join([
        :code.priv_dir(:plaza),
        "static",
        local_url
      ])

    request =
      S3.put_object(
        @aws_s3_bucket,
        local_url,
        File.read!(src)
      )

    {:ok, term} =
      ExAws.request(
        request,
        region: @aws_s3_region
      )

    IO.inspect(term)

    "https://#{@aws_s3_bucket}.s3.us-west-2.amazonaws.com/#{local_url}"
  end

  def handle_event("stripe-link-account", _params, socket) do
    Task.async(fn ->
      {:ok, %Stripe.Account{id: stripe_id}} = Stripe.Account.create(%{type: :express})

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

  def handle_event("edit-seller", _params, socket) do
    seller = socket.assigns.seller

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
      |> assign(
        local_logo_upload: %{
          url: seller.profile_photo_url,
          file_name: "your-current-logo.foto"
        }
      )
      |> assign(step: "edit-seller")

    {:noreply, socket}
  end

  def handle_event("cancel-edit-seller", _params, socket) do
    socket =
      socket
      |> assign(step: nil)

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

          IO.inspect(stripe_account_link_url)

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
             details_submitted: details_submitted
           } = stripe_account} = Stripe.Account.retrieve(stripe_id)

          seller = Accounts.get_seller_by_id(socket.assigns.current_user.id)
          products = socket.assigns.products

          {seller, products} =
            case details_submitted do
              true ->
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

              false ->
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
    IO.inspect(url)

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

  def handle_info({ref, {:logo_uploaded, s3_url, seller}}, socket) do
    Process.demonitor(ref, [:flush])

    seller = %{seller | profile_photo_url: s3_url}
    IO.inspect(seller)

    socket =
      create_or_update_seller(
        socket,
        seller
      )

    {:noreply, socket}
  end

  def create_or_update_seller(socket, seller) do
    socket =
      case socket.assigns.seller do
        nil ->
          case Accounts.create_seller(seller) do
            {:ok, seller} ->
              socket =
                case socket.assigns.product_buffer do
                  nil ->
                    socket

                  product ->
                    product = %{
                      product
                      | user_id: seller.user_id,
                        user_name: seller.user_name
                    }

                    {:ok, product} = Products.create_product(product)
                    IO.inspect(product)

                    socket =
                      socket
                      |> assign(products: [product])
                end

              socket
              |> assign(seller: seller)

            {:error, changeset} ->
              socket
              |> assign(seller_form: changeset |> to_form)
          end

        _ ->
          {:ok, seller} = Accounts.update_seller(seller)

          socket
          |> assign(seller: seller)
          |> assign(step: nil)
      end

    socket
    |> assign(waiting: false)
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
          uploads={@uploads}
          local_logo_upload={@local_logo_upload}
          seller={@seller}
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
            <ProductComponent.product product={product} meta={false} />
          </div>
        </div>
      </div>
      <div style="display: flex; justify-content: center; margin-top: 100px; margin-bottom: 50px;">
        create your store before the product goes live
      </div>
      <div>
        <.seller_form
          seller_form={@seller_form}
          uploads={@uploads}
          local_logo_upload={@local_logo_upload}
          seller={@seller}
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
          uploads={@uploads}
          local_logo_upload={@local_logo_upload}
          seller={@seller}
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
                <ProductComponent.product product={product} meta={false} />
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
    <div style="display: flex; margin-bottom: 50px;">
      <.left seller={@seller} />
      <.right products={@products} />
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
      <div style="width: 377px; overflow: hidden;">
        <img src={if @seller.profile_photo_url, do: @seller.profile_photo_url, else: "png/pep.png"} />
      </div>
      <div style="position: relative; left: 61px; width: 316px; height: 600px; border-right: 1px solid #707070;">
        <div class="is-size-6 mb-small" style="text-decoration: underline;">
          <%= @seller.user_name %>
        </div>
        <div class="is-size-6 mb-xsmall" style="line-height: 34px; width: 267px;">
          <%= @user_description %>
        </div>
        <div class="is-size-6 mb-small has-dark-gray-text">
          <%= @user_location %>
        </div>
        <div :for={url <- @user_urls} class="is-size-6" style="text-decoration: underline;">
          <.url_or url={url} />
        </div>
        <div style="margin-top: 50px; height: 30px; width: 33px; border-top: none; border-left: none; border-right: none; border-bottom: 2px solid black;">
          <button phx-click="edit-seller" class="has-font-3" style="font-size: 24px;">edit</button>
        </div>
      </div>
    </div>
    """
  end

  defp url_or(%{url: {:default, default}} = assigns) do
    ~H"""
    <div style="opacity: 70%;">
      <%= default %>
    </div>
    """
  end

  defp url_or(%{url: {:url, url}} = assigns) do
    ~H"""
    <a href={url} target="_blank">
      <%= url %>
    </a>
    """
  end

  defp right(assigns) do
    ~H"""
    <div style="margin-top: 150px;">
      <div style="position: relative; left: 100px; margin-bottom: 50px;">
        <.link navigate="/upload" style="text-decoration: underline;" class="has-font-3 is-size-6">
          upload more stuff
        </.link>
      </div>
      <div style="position: relative; left: 75px;">
        <ProductComponent.products3 products={@products} />
      </div>
      <div
        class="has-font-3"
        style="display: flex; justify-content: flex-end; position: relative; top: 50px;"
      >
        <div style="display: inline-block; position: relative; right: 200px;">
          <div class="is-size-6" style="text-decoration: underline;">
            Ver todos as produtos
          </div>
        </div>
        <div style="display: inline-block; position: relative; left: 50px;">
          <div class="is-size-6 has-dark-gray-text" style="text-decoration: underline;">
            Acessar Painel de Vendedor
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp seller_form(assigns) do
    ~H"""
    <div style="display: flex; justify-content: center;">
      <div>
        <form>
          <div :if={!@local_logo_upload[:url]}>
            <label
              class="has-font-3 is-size-4"
              style="width: 312px; height: 300px; border: 1px solid black; display: flex; justify-content: center; align-items: center;"
            >
              <.live_file_input
                upload={@uploads.logo}
                style="display: none;"
                phx-change="change-seller-logo"
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
            :if={@local_logo_upload[:url]}
            style="width: 312px; height: 300px; overflow: hidden; border: 1px solid black;"
          >
            <img src={@local_logo_upload.url} />
          </div>
          <div :if={@local_logo_upload[:file_name]} style="position: relative; left: 5px;">
            <div style="display: inline-block; width: 270px; font-size: 24px; color: gray;">
              <%= @local_logo_upload.file_name %>
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
        <div style="position: relative; left: 50px; bottom: 40px;">
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
            <div style="position: relative; top: 100px;">
              <button>
                <img src="svg/yellow-ellipse.svg" />
                <div class="has-font-3" style="position: relative; bottom: 79px; font-size: 36px;">
                  <%= if !@seller, do: "Criar Loja", else: "Editar Loja" %>
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
