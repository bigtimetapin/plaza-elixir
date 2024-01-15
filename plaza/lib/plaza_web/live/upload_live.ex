defmodule PlazaWeb.UploadLive do
  use PlazaWeb, :live_view

  require Logger

  alias Ecto.Changeset

  alias Plaza.Accounts
  alias Plaza.Accounts.Seller
  alias Plaza.Products
  alias Plaza.Products.Product
  alias Plaza.Products.Designs
  alias Plaza.Products.Mocks

  alias ExAws.S3

  ## @site "http://localhost:4000"
  @site "https://plazaaaaa-solitary-snowflake-7144-summer-wave-9195.fly.dev"
  @local_storage_key "plaza-product-form"

  @aws_s3_region "us-west-2"
  @aws_s3_bucket "plaza-static-dev"

  @default_user_name "tmp"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      case connected?(socket) do
        true ->
          {seller, user_id, user_name, active, step} =
            case socket.assigns.current_user do
              nil ->
                {nil, -1, @default_user_name, false, 1}

              %{id: id} ->
                case Accounts.get_seller_by_id(id) do
                  nil ->
                    {nil, id, @default_user_name, false, 4}

                  %{stripe_id: nil} = seller ->
                    case Products.count(id) > 0 do
                      true ->
                        {seller, id, seller.user_name, false, -1}

                      false ->
                        {seller, id, seller.user_name, false, 4}
                    end

                  seller ->
                    {seller, id, seller.user_name, true, 4}
                end
            end

          ## days
          campaign_duration = 7

          campaign_duration_timestamp =
            NaiveDateTime.utc_now()
            |> NaiveDateTime.add(campaign_duration, :day)
            |> NaiveDateTime.truncate(:second)

          socket
          |> assign(page_title: "Upload")
          |> assign(header: :my_store)
          |> assign(seller: seller)
          |> assign(
            product_form:
              to_form(
                Product.changeset(
                  %Product{
                    user_id: user_id,
                    user_name: user_name,
                    price: 75.0,
                    designs: %Designs{
                      display: 0
                    },
                    mocks: %Mocks{
                      front:
                        "https://plaza-static-dev.s3.us-west-2.amazonaws.com/uploads/mockup-front.png",
                      back:
                        "https://plaza-static-dev.s3.us-west-2.amazonaws.com/uploads/mockup-back.png"
                    },
                    campaign_duration: campaign_duration,
                    campaign_duration_timestamp: campaign_duration_timestamp,
                    active: active,
                    curated: false
                  },
                  %{}
                )
              )
          )
          |> assign(front_local_upload: nil)
          |> assign(back_local_upload: nil)
          |> assign(publish_status: 0)
          |> assign(:uuid, UUID.uuid1())
          |> assign(step: step)
          |> assign(waiting: false)
          |> push_event(
            "read",
            %{
              key: @local_storage_key,
              event: "read-product-form"
            }
          )

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

  def handle_event("read-product-form", token_data, socket) when is_binary(token_data) do
    socket =
      case restore_from_token(token_data) do
        {:ok, nil} ->
          # do nothing with the previous state
          socket

        {:ok, restored} ->
          case socket.assigns.step do
            1 ->
              socket
              |> assign(product_buffer: restored)
              |> assign(step: -2)

            _ ->
              socket
          end

        {:error, reason} ->
          # We don't continue checking. Display error.
          # Clear the token so it doesn't keep showing an error.
          socket
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

  def handle_event("step", %{"step" => "noop"}, socket) do
    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "2"}, socket) do
    socket =
      socket
      |> assign(:step, 2)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "3"}, socket) do
    socket =
      socket
      |> assign(:step, 4)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "4"}, socket) do
    socket =
      socket
      |> assign(:step, 4)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "5"}, socket) do
    socket =
      socket
      |> assign(:step, 5)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "6"}, socket) do
    socket =
      socket
      |> assign(:step, 6)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "7"}, socket) do
    socket =
      socket
      |> assign(:step, 7)
      |> assign(:uuid, UUID.uuid1())

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "8"}, socket) do
    socket =
      socket
      |> assign(:step, 8)

    {:noreply, socket}
  end

  def handle_event("change-product-display", _params, socket) do
    product = socket.assigns.product_form.data

    designs = product.designs

    product_display =
      case designs.display do
        0 -> 1
        1 -> 0
      end

    designs = %{designs | display: product_display}

    changes =
      Product.changeset_designs(
        product,
        %{"designs" => designs}
      )
      |> Changeset.apply_action(:update)

    form =
      case changes do
        {:error, changeset} ->
          to_form(changeset)

        {:ok, product} ->
          Product.changeset(
            product,
            %{}
          )
          |> Map.put(:action, :validate)
          |> to_form
      end

    socket =
      socket
      |> assign(:product_form, form)

    {:noreply, socket}
  end

  def handle_event("change-product-form", %{"product" => product}, socket) do
    changes =
      Product.changeset_name_and_description(
        socket.assigns.product_form.data,
        product
      )
      |> Changeset.apply_action(:update)

    form =
      case changes do
        {:error, changeset} ->
          to_form(changeset)

        {:ok, product} ->
          Product.changeset(
            product,
            %{}
          )
          |> Map.put(:action, :validate)
          |> to_form
      end

    socket =
      socket
      |> assign(:product_form, form)
      |> assign(:uuid, UUID.uuid1())

    {:noreply, socket}
  end

  def handle_event("change-product-price", %{"product" => %{"price" => price_as_string}}, socket) do
    price_attr =
      case price_as_string do
        "" ->
          %{}

        nes ->
          case Float.parse(nes) do
            {float, ""} -> %{"price" => float}
            _ -> %{}
          end
      end

    changes =
      Product.changeset_price(
        socket.assigns.product_form.data,
        price_attr
      )
      |> Changeset.apply_action(:update)

    form =
      case changes do
        {:error, changeset} ->
          to_form(changeset)

        {:ok, product} ->
          Product.changeset(
            product,
            %{}
          )
          |> Map.put(:action, :validate)
          |> to_form
      end

    socket =
      socket
      |> assign(:product_form, form)
      |> assign(:uuid, UUID.uuid1())

    {:noreply, socket}
  end

  def handle_event("change-campaign-duration", %{"duration" => duration_str}, socket) do
    duration =
      case duration_str do
        "7" -> 7
        "14" -> 14
        "21" -> 21
        "30" -> 30
        "45" -> 45
      end

    duration_timestap =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(duration, :day)
      |> NaiveDateTime.truncate(:second)

    duration_attr = %{
      "campaign_duration" => duration,
      "campaign_duration_timestamp" => duration_timestap
    }

    changes =
      Product.changeset_campaign_duration(
        socket.assigns.product_form.data,
        duration_attr
      )
      |> Changeset.apply_action(:update)

    form =
      case changes do
        {:error, changeset} ->
          to_form(changeset)

        {:ok, product} ->
          Product.changeset(
            product,
            %{}
          )
          |> Map.put(:action, :validate)
          |> to_form
      end

    socket =
      socket
      |> assign(:product_form, form)
      |> assign(:uuid, UUID.uuid1())

    {:noreply, socket}
  end

  def handle_event("front-upload-change", file_name, socket) do
    socket =
      socket
      |> assign(front_local_upload: file_name)

    {:noreply, socket}
  end

  def handle_event("back-upload-change", file_name, socket) do
    socket =
      socket
      |> assign(back_local_upload: file_name)

    {:noreply, socket}
  end

  def handle_event("front-upload-cancel", _, socket) do
    socket =
      socket
      |> assign(front_local_upload: nil)
      |> assign(:uuid, UUID.uuid1())
      |> push_event("front-upload-cancel", %{})

    {:noreply, socket}
  end

  def handle_event("back-upload-cancel", _, socket) do
    socket =
      socket
      |> assign(back_local_upload: nil)
      |> assign(:uuid, UUID.uuid1())
      |> push_event("back-upload-cancel", %{})

    {:noreply, socket}
  end

  def handle_event("s3-upload-complete", side, socket) do
    publish_status = socket.assigns.publish_status + 1
    product = socket.assigns.product
    designs = product.designs
    mocks = product.mocks
    url = "https://#{@aws_s3_bucket}.s3.#{@aws_s3_region}.amazonaws.com"

    {designs, mocks} =
      case side do
        "front-design" ->
          file_name = URI.encode(socket.assigns.front_local_upload)
          {%{designs | front: "#{url}/#{file_name}"}, mocks}

        "front-mock" ->
          file_name = URI.encode("mock_#{socket.assigns.front_local_upload}")
          {designs, %{mocks | front: "#{url}/#{file_name}"}}

        "back-design" ->
          file_name = URI.encode(socket.assigns.back_local_upload)
          {%{designs | back: "#{url}/#{file_name}"}, mocks}

        "back-mock" ->
          file_name = URI.encode("mock_#{socket.assigns.back_local_upload}")
          {designs, %{mocks | back: "#{url}/#{file_name}"}}
      end

    product = %{product | designs: designs, mocks: mocks}

    socket =
      case publish_status do
        4 ->
          case socket.assigns.seller do
            nil ->
              socket
              |> assign(write_status: :local_storage)
              |> assign(step: 9)
              |> push_event("write", %{
                key: @local_storage_key,
                data: serialize_to_token(product)
              })
              |> assign(waiting: false)

            seller ->
              {:ok, product} = Products.create_product(product)

              socket
              |> assign(write_status: :db_storage)
              |> assign(product: product)
              |> assign(step: 9)
              |> assign(waiting: false)
          end

        _ ->
          socket
          |> assign(product: product)
          |> assign(publish_status: publish_status)
      end

    {:noreply, socket}
  end

  def handle_event("publish", _params, socket) do
    url = "https://#{@aws_s3_bucket}.s3-#{@aws_s3_region}.amazonaws.com"

    config = %{
      region: @aws_s3_region,
      access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID_PLAZA"),
      secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY_PLAZA")
    }

    socket =
      socket
      |> assign(product: socket.assigns.product_form.data)
      |> assign(waiting: true)

    socket = push_upload_event(socket, config, url, "front", socket.assigns.front_local_upload)
    socket = push_upload_event(socket, config, url, "back", socket.assigns.back_local_upload)

    {:noreply, socket}
  end

  defp push_upload_event(socket, config, url, side, maybe_file_name) do
    case maybe_file_name do
      nil ->
        socket
        |> assign(publish_status: socket.assigns.publish_status + 2)

      file_name ->
        {:ok, design_fields} =
          PlazaWeb.S3UrlPresign.sign_form_upload(
            config,
            @aws_s3_bucket,
            key: file_name,
            content_type: "image/png",
            max_file_size: 10_000_000,
            expires_in: :timer.hours(1)
          )

        {:ok, mock_fields} =
          PlazaWeb.S3UrlPresign.sign_form_upload(
            config,
            @aws_s3_bucket,
            key: "mock_#{file_name}",
            content_type: "image/png",
            max_file_size: 10_000_000,
            expires_in: :timer.hours(1)
          )

        socket
        |> push_event("upload", %{
          url: url,
          design_fields: design_fields,
          mock_fields: mock_fields,
          side: side
        })
    end
  end

  defp serialize_to_token(state_data) do
    salt = Application.get_env(:plaza, PlazaWeb.Endpoint)[:live_view][:signing_salt]
    Phoenix.Token.encrypt(PlazaWeb.Endpoint, salt, state_data)
  end

  @impl Phoenix.LiveView
  def render(%{waiting: true} = assigns) do
    ~H"""
    <div style="margin-top: 200px; display: flex; justify-content: center;">
      <img src="gif/loading.gif" />
    </div>
    """
  end

  def render(%{step: -2, product_buffer: product} = assigns) do
    ~H"""
    <div class="has-font-3 is-size-4" style="margin-top: 125px; margin-bottom: 125px;">
      <div style="display: flex; justify-content: center;">
        <div style="display: flex; flex-direction: column; align-items: center; width: 500px;">
          <div>
            <PlazaWeb.ProductComponent.product product={product} meta={false} disabled={true} />
          </div>
          <div style="text-align: center;">
            you've already uploaded your first product but haven't created a seller profile yet.
            <.link
              navigate="/my-store"
              style="margin-left: 5px; margin-right: 5px; text-decoration: underline;"
            >
              go do that
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(%{step: -1} = assigns) do
    ~H"""
    <div class="has-font-3 is-size-4" style="margin-top: 125px; margin-bottom: 125px;">
      <div style="display: flex; justify-content: center;">
        <div style="width: 500px; text-align: center;">
          you've already uploaded your first product but haven't linked your bank account yet.
          <.link
            navigate="/my-store"
            style="margin-left: 5px; margin-right: 5px; text-decoration: underline;"
          >
            go do that
          </.link>
          to activate your first product and continue uploading more products.
        </div>
      </div>
    </div>
    """
  end

  def render(%{step: 1} = assigns) do
    ~H"""
    <div class="has-font-3 is-size-4" style="text-align: center; margin-top: 125px;">
      <div class="mb-xsmall">
        É Fácil e totalmente grátis.
      </div>
      <div class="mb-xsmall">
        Você faz o upload da sua arte, configura o produto, escolhe o preço de venda e publica sua campanha de vendas.
      </div>
      <div class="mb-xsmall">
        A partir daí você só precisa esperar pra receber seus lucros.
      </div>
      <div class="mb-xsmall">
        A gente vai produzir cada produto vendido e entregar direto na casa do cliente.
      </div>
      <div class="mb-xxsmall">
        <div>
          Fabricamos apenas o que for vendido, assim não temos desperdício de recursos.
        </div>
        <div style="position: relative; bottom: 15px;">
          Você recebe pelo que vender.
        </div>
      </div>
      <div class="mb-xsmall">
        E se não vender tudo bem, ninguém perde nada.
      </div>
    </div>
    <div style="display: flex; justify-content: center; margin-top: 85px; margin-bottom: 75px;">
      <button phx-click="step" phx-value-step="2">
        <img src="svg/yellow-ellipse.svg" />
        <div class="has-font-3 is-size-4" style="position: relative; bottom: 79px;">
          Criar Produto
        </div>
      </button>
    </div>
    """
  end

  def render(%{step: 2} = assigns) do
    ~H"""
    <div class="has-font-3 is-size-4" style="text-align: center; margin-top: 150px;">
      <div class="mb-xsmall">
        Tem mais um detalhe importante:
      </div>
      <div class="mb-xsmall">
        <div>
          Seu produto vai ficar disponível na nossa loja por tempo limitado.
        </div>
        <div style="position: relative; bottom: 15px;">
          Você pode decidir se sua campanha de vendas ficará disponível por 7, 14, 21 ou 30 dias.
        </div>
      </div>
      <div>
        <div>
          Após o final do prazo de vendas seu produto não estará mais disponível para encomendas.
        </div>
        <div style="position: relative; bottom: 15px;">
          Você tem liberdade de republicar o produto por mais períodos de até 30 dias novamente se quiser.
        </div>
      </div>
    </div>
    <div style="display: flex; justify-content: center; margin-top: 85px; margin-bottom: 50px;">
      <button phx-click="step" phx-value-step="3">
        <img src="svg/yellow-ellipse.svg" />
        <div class="has-font-3 is-size-4" style="position: relative; bottom: 79px;">
          Ok
        </div>
      </button>
    </div>
    """
  end

  def render(%{step: 4} = assigns) do
    ~H"""
    <.upload_generic
      step={@step}
      side="front"
      front_local_upload={@front_local_upload}
      back_local_upload={@back_local_upload}
      product_form={@product_form}
      uuid={@uuid}
    />
    """
  end

  def render(%{step: 5} = assigns) do
    ~H"""
    <.upload_generic
      step={@step}
      side="back"
      front_local_upload={@front_local_upload}
      back_local_upload={@back_local_upload}
      product_form={@product_form}
      uuid={@uuid}
    />
    """
  end

  def render(%{step: 6} = assigns) do
    ~H"""
    <div style="margin-top: 150px; margin-bottom: 750px;">
      <PlazaWeb.UploadLive.header
        step={@step}
        front_local_upload={@front_local_upload}
        back_local_upload={@back_local_upload}
        product_form={@product_form}
      />
      <div style="display: flex; justify-content: center;  margin-top: 50px;">
        <div class="has-font-3" style="font-size: 30px;">
          <div style="display: flex; justify-content: center; margin-bottom: 25px;">
            Seu produto ficou assim:
          </div>
          <div style="position: relative;">
            <button phx-click="step" phx-value-step="7">
              <img src="svg/yellow-ellipse.svg" />
              <div class="has-font-3 is-size-4" style="position: relative; bottom: 79px;">
                Próximo
              </div>
            </button>
          </div>
          <div>
            <div style="display: inline-block;">
              <.upload_preview step={@step} side="front" />
              <div style="position: relative; bottom: 350px; left: 10px; font-size: 34px;">
                Frente
              </div>
            </div>
            <div style="display: inline-block; margin-left: 150px;">
              <.upload_preview step={@step} side="back" />
              <div style="position: relative; bottom: 350px; left: 10px; font-size: 34px;">
                Costas
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(%{step: 7} = assigns) do
    ~H"""
    <div class="has-font-3" style="margin-top: 150px; margin-bottom: 750px; font-size: 34px;">
      <PlazaWeb.UploadLive.header
        step={@step}
        front_local_upload={@front_local_upload}
        back_local_upload={@back_local_upload}
        product_form={@product_form}
      />
      <div style="display: inline-block; margin-left: 50px;">
        <div>
          Foto do seu produto na loja:
          <button
            :if={@product_form.data.designs.display == 0}
            class="has-font-3"
            style="border-bottom: 2px solid black; height: 45px;"
          >
            Frente
          </button>
          <button
            :if={@product_form.data.designs.display == 0}
            class="has-font-3"
            phx-click="change-product-display"
          >
            / Costas
          </button>

          <button
            :if={@product_form.data.designs.display == 1}
            class="has-font-3"
            phx-click="change-product-display"
          >
            Frente
          </button>
          <button
            :if={@product_form.data.designs.display == 1}
            class="has-font-3"
            style="border-bottom: 2px solid black; height: 45px;"
          >
            / Costas
          </button>
          <div style="margin-top: 10px;">
            <div :if={@product_form.data.designs.display == 0}>
              <.upload_preview step={@step} side="front" uid={@uuid} />
            </div>
            <div :if={@product_form.data.designs.display == 1}>
              <.upload_preview step={@step} side="back" uid={@uuid} />
            </div>
          </div>
        </div>
      </div>
      <div style="display: inline-block; position: absolute;">
        <div style="position: relative; left: 50px; top: 50px;">
          <div style="position: absolute;">
            <div
              :if={
                @product_form.data.name && @product_form.data.description &&
                  @product_form.data.price
              }
              style="position: relative; top: 450px; left: 550px;"
            >
              <button phx-click="step" phx-value-step="8">
                <img src="svg/yellow-ellipse.svg" />
                <div class="has-font-3 is-size-4" style="position: relative; bottom: 79px;">
                  Próximo
                </div>
              </button>
            </div>
          </div>
          <.form for={@product_form} phx-change="change-product-form" phx-submit="submit-product-form">
            <div style="display: inline-block;">
              <div>
                <.input
                  field={@product_form[:name]}
                  type="textarea"
                  placeholder="*Nome do produto"
                  style="color: #707070; font-size: 36px; text-decoration-line: underline; border: none;"
                  class="has-font-3"
                  phx-debounce="500"
                >
                </.input>
              </div>
              <div>
                <.input
                  field={@product_form[:description]}
                  type="textarea"
                  placeholder="*Descrição"
                  style="color: #707070; font-size: 28px; text-decoration-line: underline; border: none; width: 500px; height: 250px;"
                  class="has-font-3"
                  phx-debounce="500"
                >
                </.input>
              </div>
            </div>
            <div style="display: inline-block; position: absolute;">
              <div style="position: relative; left: 10px; width: 750px;">
                <div>
                  Defina o preço final de venda:
                </div>
                <div style="position: relative; bottom: 98px; left: 370px;">
                  <div style="position: absolute;">
                    <div style="position: relative; top: 26px; left: 17px; background-color: #F8FC5F; width: 20px; z-index: 99;">
                      R$
                    </div>
                  </div>
                  <.input
                    field={@product_form[:price]}
                    value={@product_form.data.price}
                    type="number"
                    phx-change="change-product-price"
                    class="has-font-3"
                    style="font-size: 34px; border: 1px solid gray; background-color: #F8FC5F; width: 150px; height: 100px; border-radius: 50px; padding-left: 50px;"
                  >
                  </.input>
                </div>
                <div style="position: relative; bottom: 50px;">
                  Se vender 30 unidades seu lucro será: R$<%= (@product_form.data.price - 50) * 30 %>
                </div>
              </div>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  def render(%{step: 8} = assigns) do
    ~H"""
    <div class="has-font-3" style="margin-top: 150px; margin-bottom: 750px; font-size: 34px;">
      <PlazaWeb.UploadLive.header
        step={@step}
        front_local_upload={@front_local_upload}
        back_local_upload={@back_local_upload}
        product_form={@product_form}
      />
      <div style="display: flex; justify-content: center;  margin-top: 50px;">
        <div style="display: inline-block;">
          <.upload_preview
            step={@step}
            side={if @product_form.data.designs.display == 0, do: "front", else: "back"}
            size="small"
            uid={@uuid}
          />
          <div style="position: relative; right: 3px;">
            <div style="display: flex; justify-content: right; font-size: 22px;">
              R$ <%= @product_form.data.price %>
              <div style="position: absolute;">
                <div style="position: relative; top: 35px; font-size: 16px; color: #707070;">
                  Disponível por mais <%= @product_form.data.campaign_duration %> dias
                </div>
              </div>
            </div>
          </div>
        </div>
        <div style="display: inline-block; margin-left: 50px; width: 700px;">
          <div style="position: relative; bottom: 50px;">
            <div style="display: inline-block;">
              Quantos dias seu produto ficará no ar:
            </div>
            <div style="display: inline-block;">
              <button
                class="has-font-3"
                style="font-size: 34px;"
                phx-click="change-campaign-duration"
                phx-value-duration="7"
              >
                <img
                  :if={@product_form.data.campaign_duration == 7}
                  src="svg/yellow-circle.svg"
                  style="position: relative; top: 47px;"
                />
                <div style="position: relative;">
                  7
                </div>
              </button>
              /
              <button
                class="has-font-3"
                style="font-size: 34px;"
                phx-click="change-campaign-duration"
                phx-value-duration="14"
              >
                <img
                  :if={@product_form.data.campaign_duration == 14}
                  src="svg/yellow-circle.svg"
                  style="position: relative; top: 47px;"
                />
                <div style="position: relative;">
                  14
                </div>
              </button>
              /
              <button
                class="has-font-3"
                style="font-size: 34px;"
                phx-click="change-campaign-duration"
                phx-value-duration="21"
              >
                <img
                  :if={@product_form.data.campaign_duration == 21}
                  src="svg/yellow-circle.svg"
                  style="position: relative; top: 47px;"
                />
                <div style="position: relative;">
                  21
                </div>
              </button>
              /
              <button
                class="has-font-3"
                style="font-size: 34px;"
                phx-click="change-campaign-duration"
                phx-value-duration="30"
              >
                <img
                  :if={@product_form.data.campaign_duration == 30}
                  src="svg/yellow-circle.svg"
                  style="position: relative; top: 47px;"
                />
                <div style="position: relative;">
                  30
                </div>
              </button>
              /
              <button
                class="has-font-3"
                style="font-size: 34px;"
                phx-click="change-campaign-duration"
                phx-value-duration="45"
              >
                <img
                  :if={@product_form.data.campaign_duration == 45}
                  src="svg/yellow-circle.svg"
                  style="position: relative; top: 47px;"
                />
                <div style="position: relative;">
                  45
                </div>
              </button>
            </div>
          </div>
          <div style="display: flex; justify-content: center; margin-top: 50px;">
            <div>
              Você terminou de configurar seu produto, publicar na loja?
              <div style="display: flex; justify-content: center; margin-top: 25px;">
                <button phx-click="publish">
                  <img src="svg/yellow-ellipse.svg" />
                  <div class="has-font-3" style="position: relative; bottom: 79px; font-size: 36px;">
                    Publicar
                  </div>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(%{step: 9, write_status: :db_storage, product: product} = assigns) do
    product_params = %{"product-id" => product.id}

    assigns =
      assigns
      |> assign(:product_params, product_params)

    ~H"""
    <div class="has-font-3" style="margin-top: 150px; margin-bottom: 750px;">
      <div style="display: flex; justify-content: center;">
        <div style="font-size: 40px;">
          Produto publicado com sucesso!
          <div style="display: flex; justify-content: center; font-size: 34px; margin-top: 25px;">
            <.link navigate={"/product?#{URI.encode_query(@product_params)}"}>
              <div style="display: inline-block; border-bottom: 2px solid black; height: 45px;">
                V
              </div>
              <div style="display: inline-block; position: relative; right: 6px;">
                isitar página do produto
              </div>
            </.link>
          </div>
          <div style="display: flex; justify-content: center; margin-top: 75px; font-size: 34px;">
            Copiar link para compartilhar
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(%{step: 9, write_status: :local_storage} = assigns) do
    ~H"""
    <div class="has-font-3" style="margin-top: 150px; margin-bottom: 750px;">
      <div style="display: flex; justify-content: center;">
        <div style="font-size: 40px;">
          <div style="display: flex; justify-content: center;">
            Produto publicado com sucesso!
          </div>
          <div style=" font-size: 34px; margin-top: 25px;">
            <.link navigate="/my-store">
              <div style="display: inline-block; border-bottom: 2px solid black; height: 45px;">
                V
              </div>
              <div style="display: inline-block; position: relative; right: 6px;">
                isitar your store to finish registering before this product is live
              </div>
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(%{step: 9, write_status: :error} = assigns) do
    ~H"""
    <div class="has-font-3" style="margin-top: 150px; margin-bottom: 750px; font-size: 34px;">
      error
    </div>
    """
  end

  attr :step, :integer, required: true
  attr :disabled, :boolean, default: false
  attr :product_form, :map, required: true
  attr :front_local_upload, :string, required: true
  attr :back_local_upload, :string, required: true

  def header(assigns) do
    ~H"""
    <div style="display: flex; justify-content: center;">
      <nav class="has-font-3 is-size-5">
        <a
          phx-click="step"
          phx-value-step={if @disabled, do: "noop", else: "4"}
          class="has-black-text mr-small"
          style="display: inline-block;"
        >
          Configurar Estampa
          <img
            :if={Enum.member?([3, 4, 5, 6], @step)}
            src="svg/yellow-circle.svg"
            style="position: relative; left: 87px;"
          />
        </a>
        <img src="svg/seperator.svg" class="mr-small" style="display: inline-block;" />
        <a
          phx-click="step"
          phx-value-step={
            if @disabled || !(@front_local_upload || @back_local_upload),
              do: "noop",
              else: "7"
          }
          class="has-black-text mr-small"
          style="display: inline-block;"
        >
          Configuração de Campanha
          <img :if={@step == 7} src="svg/yellow-circle.svg" style="position: relative; left: 123px;" />
        </a>
        <img src="svg/seperator.svg" class="mr-small" style="display: inline-block;" />
        <a
          phx-click="step"
          phx-value-step={
            if @disabled ||
                 !(@product_form.data.name && @product_form.data.description &&
                     @product_form.data.price),
               do: "noop",
               else: "8"
          }
          class="has-black-text"
          style="display: inline-block;"
        >
          Publique seu Produto
          <img :if={@step == 8} src="svg/yellow-circle.svg" style="position: relative; left: 93px;" />
        </a>
      </nav>
    </div>
    """
  end

  attr :step, :integer, required: true
  attr :side, :string, values: ~w(front back)
  attr :front_local_upload, :string, required: true
  attr :back_local_upload, :string, required: true
  attr :product_form, :map, required: true
  attr :uuid, :string, default: "uuid"

  defp upload_generic(assigns) do
    ~H"""
    <div
      id={"plaza-file-uploader-#{@step}"}
      phx-hook="FileReader"
      style="margin-top: 150px; margin-bottom: 750px;"
    >
      <PlazaWeb.UploadLive.header
        step={@step}
        front_local_upload={@front_local_upload}
        back_local_upload={@back_local_upload}
        product_form={@product_form}
      />

      <div style="display: inline-block; position: absolute; margin-left: 50px;">
        <div style="margin-top: 50px;">
          <.upload_form
            side={@side}
            front_local_upload={@front_local_upload}
            back_local_upload={@back_local_upload}
          />
        </div>
      </div>
      <div style="display: inline-block; position: relative; left: 900px; top: 50px;">
        <div style="display: inline-block;">
          <.upload_preview step={@step} side={@side} uid={@uuid} />
        </div>
        <div style="display: inline-block; position: absolute;">
          <div style="position: relative; left: 25px;">
            <.upload_toggle
              step={@step}
              front_local_upload={@front_local_upload}
              back_local_upload={@back_local_upload}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :side, :string, values: ~w(front back)
  attr :front_local_upload, :string, required: true
  attr :back_local_upload, :string, required: true

  defp upload_form(assigns) do
    ~H"""
    <div>
      <.upload_input side={@side} />
      <div class="has-font-3" style="width: 760px; font-size: 28px;">
        <div style="margin-top: 25px;">
          Arquivo PNG com formato de cores RGB com pelo menos 300 dpi de resolução.
          Medidas ajustadas dentro dos limites do A3 (29 x 42 cm)
        </div>
        <div style="margin-top: 50px; margin-left: 20px;">
          Seus arquivos:
        </div>
      </div>
      <div style="margin-left: 20px;">
        <.upload_item side="front" local_upload={@front_local_upload} no_file_yet="front.png" />
        <.upload_item side="back" local_upload={@back_local_upload} no_file_yet="back.png" />
      </div>
    </div>
    """
  end

  attr :side, :string, values: ~w(front back)

  defp upload_input(assigns) do
    ~H"""
    <div>
      <form>
        <label
          class="has-font-3 is-size-4"
          style="width: 760px; height: 130px; border: 1px solid black; display: flex; justify-content: center; align-items: center;"
        >
          <input
            type="file"
            id={"plaza-file-input-#{@side}"}
            accept=".png"
            multiple={false}
            style="display: none;"
          /> Arraste seus arquivos .png aqui para fazer upload
        </label>
      </form>
    </div>
    """
  end

  attr :side, :string, values: ~w(front back)
  attr :local_upload, :string, required: true
  attr :no_file_yet, :string, required: true

  defp upload_item(assigns) do
    ~H"""
    <div>
      <div class="has-font-3 is-size-6">
        <%= if @local_upload,
          do:
            if(String.length(@local_upload) >= 20,
              do: "#{String.slice(@local_upload, 0, 10)}...#{String.slice(@local_upload, -9, 9)}",
              else: @local_upload
            ),
          else: @no_file_yet %>
        <button
          :if={@local_upload}
          type="button"
          phx-click={"#{@side}-upload-cancel"}
          aria-label="cancel"
        >
          &times;
        </button>
      </div>
    </div>
    """
  end

  attr :step, :integer, required: true
  attr :side, :string, values: ~w(front back)
  attr :size, :string, default: "big", values: ~w(big small)
  attr :uid, :string, default: "uid"

  defp upload_preview(assigns) do
    ~H"""
    <div
      id={"plaza-file-display-container-#{@step}-#{@side}-#{@uid}"}
      phx-hook="FileDisplay"
      style={if @size == "small", do: "width: 400px;", else: "width: 650px;"}
    >
      <img
        id={"plaza-file-display-#{@side}"}
        src={if @side == "front", do: "png/mockup-front.png", else: "png/mockup-back.png"}
      />
    </div>
    """
  end

  attr :step, :integer, required: true
  attr :front_local_upload, :string, required: true
  attr :back_local_upload, :string, required: true

  defp upload_toggle(assigns) do
    ~H"""
    <div>
      <div>
        <button
          :if={@step == 4}
          class="has-font-3 is-size-5"
          style="border-bottom: 2px solid black; height: 43px;"
        >
          Frente
        </button>
        <button
          :if={@step == 5}
          phx-click="step"
          phx-value-step="4"
          class="has-font-3 is-size-5"
          style="height: 43px;"
        >
          Frente
        </button>
      </div>
      <div>
        <button
          :if={@step == 4}
          phx-click="step"
          phx-value-step="5"
          type="submit"
          class="has-font-3 is-size-5"
          style="height: 43px;"
        >
          Costas
        </button>
        <button
          :if={@step == 5}
          class="has-font-3 is-size-5"
          style="border-bottom: 2px solid black; height: 43px;"
        >
          Costas
        </button>
      </div>
      <div style="position: relative; top: 620px; width: 200px;">
        <button :if={@front_local_upload || @back_local_upload} phx-click="step" phx-value-step="6">
          <img src="svg/yellow-ellipse.svg" />
          <div class="has-font-3 is-size-4" style="position: relative; bottom: 79px;">
            Próximo
          </div>
        </button>
      </div>
    </div>
    """
  end
end
