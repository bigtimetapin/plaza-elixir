defmodule PlazaWeb.MyStoreLive do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias Plaza.Accounts.Seller
  alias Plaza.Products
  alias PlazaWeb.ProductComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    seller = Accounts.get_seller_by_id(socket.assigns.current_user.id)
    IO.inspect(seller)
    my_products = Products.list_products_by_user_id(socket.assigns.current_user.id)

    socket =
      socket
      |> assign(:header, :my_store)
      |> assign(:seller, seller)
      |> assign(:my_products, my_products)
      |> allow_upload(:logo, accept: ~w(.png .jpg .jpeg .svg .gif), max_entries: 1)
      |> assign(:seller_form, to_form(Seller.changeset(%Seller{}, %{})))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("product-href", %{"product-name" => product_name}, socket) do
    seller = Accounts.get_seller_by_id(socket.assigns.current_user.id)
    params = %{"seller_name" => seller.user_name, "product-name" => product_name}
    url = URI.encode_query(params)
    IO.inspect(url)
    {:noreply, push_navigate(socket, to: "/product?#{url}")}
  end

  def handle_event("change-seller-form", %{"seller" => seller}, socket) do
    form =
      Seller.changeset(
        %Seller{},
        seller
        |> Map.put(
          "user_id",
          socket.assigns.current_user.id
        )
      )
      |> Map.put(:action, :validate)
      |> to_form

    IO.inspect(form)

    socket =
      socket
      |> assign(seller_form: form)

    IO.inspect(socket.assigns.seller_form[:user_name])

    {:noreply, socket}
  end

  def handle_event("change-seller-logo", _params, socket) do
    IO.inspect(socket.assigns.uploads.logo)
    IO.inspect(socket.assigns.seller_form)
    {:noreply, socket}
  end

  def handle_event("logo-upload-cancel", %{"ref" => ref}, socket) do
    {:noreply, Phoenix.LiveView.cancel_upload(socket, :logo, ref)}
  end

  def handle_event("submit-seller-form", %{"seller" => seller}, socket) do
    IO.inspect(socket.assigns.seller_form)
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div style="margin-bottom: 50px;">
      <.left />
      <.right my_products={@my_products} />
    </div>
    """
  end

  defp left(assigns) do
    ~H"""
    <div class="has-font-3" style="display: inline-block; position: relative; top: 50px;">
      <div>
        <img src="png/pep.png" style="width: 377px;" />
      </div>
      <div style="position: relative; left: 61px; width: 316px; height: 423px; border-right: 1px solid #707070;">
        <div class="is-size-6 mb-small" style="text-decoration: underline;">
          username
        </div>
        <div class="is-size-6 mb-xsmall" style="line-height: 34px; width: 267px;">
          Breve descrição do artista. Maximo 140 caracteres.
        </div>
        <div class="is-size-6 mb-small has-dark-gray-text">
          Localização do artista.
        </div>
        <div class="is-size-6" style="text-decoration: underline;">
          Instagram
        </div>
        <div class="is-size-6" style="text-decoration: underline;">
          Email
        </div>
        <div class="is-size-6" style="text-decoration: underline;">
          Soundcloud
        </div>
        <div class="is-size-6" style="text-decoration: underline;">
          Website
        </div>
        <div class="is-size-6" style="text-decoration: underline;">
          Twitter
        </div>
      </div>
    </div>
    """
  end

  defp right(assigns) do
    ~H"""
    <div style="display: inline-block;">
      <div style="position: relative; left: 75px; bottom: 175px;">
        <ProductComponent.products3 disabled={false} products={@my_products} href={true} />
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

  defp seller_form_wip(assigns) do
    ~H"""
    <div style="display: flex; justify-content: center;">
      <.form for={@seller_form} phx-change="change-seller-form" phx-submit="submit-seller-form">
        <div style="display: inline-block;">
          <div style="position: absolute;">
            <div style="position: relative; bottom: 335px; right: 315px;">
              <div>
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
              <div>
                <.upload_item upload={@uploads.logo} />
              </div>
            </div>
          </div>
        </div>
        <div style="display: inline-block; position: relative;left: 50px;">
          <.input
            field={@seller_form[:user_name]}
            type="text"
            placeholder="username / nome da loja *"
            class="text-input-1"
          >
          </.input>
          <.input
            field={@seller_form[:website]}
            type="text"
            placeholder="website"
            class="text-input-1"
          >
          </.input>
          <.input
            field={@seller_form[:instagram]}
            type="text"
            placeholder="instagram"
            class="text-input-1"
          >
          </.input>
          <.input
            field={@seller_form[:twitter]}
            type="text"
            placeholder="twitter"
            class="text-input-1"
          >
          </.input>
          <.input
            field={@seller_form[:soundcloud]}
            type="text"
            placeholder="soundcloud"
            class="text-input-1"
          >
          </.input>
        </div>
      </.form>
    </div>
    """
  end

  attr :upload, Phoenix.LiveView.UploadConfig, required: true
  attr :no_file_yet, :string, default: nil

  defp upload_item(assigns) do
    map =
      case assigns.upload.entries do
        [head | []] ->
          head

        _ ->
          %{client_name: assigns.no_file_yet, client_size: 0}
      end

    assigns =
      assigns
      |> assign(entry: map)

    ~H"""
    <div>
      <div class="has-font-3 is-size-6">
        <%= @entry.client_name %>
        <button
          :if={@entry.client_size > 0}
          type="button"
          phx-click={"#{@entry.upload_config}-upload-cancel"}
          phx-value-ref={@entry.ref}
          aria-label="cancel"
        >
          &times;
        </button>
      </div>
    </div>
    """
  end
end
