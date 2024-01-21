defmodule PlazaWeb.ArtistLive do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias Plaza.Products
  alias PlazaWeb.ProductComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      case connected?(socket) do
        false ->
          socket
          |> assign(waiting: true)

        true ->
          socket
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"user_name" => user_name}, uri, socket) do
    socket =
      case connected?(socket) do
        true ->
          seller = Accounts.get_seller_by_user_name(user_name)

          products =
            case seller do
              nil ->
                nil

              _ ->
                Products.list_active_products_by_user_id(seller.user_id, 3)
            end

          socket
          |> assign(seller: seller)
          |> assign(products: products)
          |> assign(all_products: false)
          |> assign(waiting: false)

        false ->
          socket
      end

    {:noreply, socket}
  end

  def handle_params(_, uri, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("all-products", _, socket) do
    products = Products.list_active_products_by_user_id(socket.assigns.seller.user_id)

    socket =
      socket
      |> assign(products: products)
      |> assign(all_products: true)

    {:noreply, socket}
  end

  def handle_event("product-href", %{"product-id" => product_id}, socket) do
    params = %{"product-id" => product_id}
    url = URI.encode_query(params)
    {:noreply, push_navigate(socket, to: "/product?#{url}")}
  end

  @impl Phoenix.LiveView
  def render(%{waiting: true} = assigns) do
    ~H"""
    <div style="margin-top: 200px; display: flex; justify-content: center;">
      <img src="gif/loading.gif" />
    </div>
    """
  end

  def render(%{seller: nil} = assigns) do
    ~H"""
    <div class="has-font-3" style="display: flex; justify-content: center; font-size: 28px;">
      <div>
        não existe
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
      |> assign(user_urls: urls)

    ~H"""
    <div class="has-font-3" style="position: relative; top: 50px;">
      <div style="width: 377px; overflow: hidden;">
        <img src={if @seller.profile_photo_url, do: @seller.profile_photo_url, else: "png/pep.png"} />
      </div>
      <div style="display: flex; flex-direction: column;">
        <div style="margin-left: auto; padding-top: 10px; width: 316px; height: 600px;">
          <div class="is-size-6 mb-small" style="text-decoration: underline;">
            <%= @seller.user_name %>
          </div>
          <div
            :if={@seller.description}
            class="is-size-6 mb-xsmall"
            style="line-height: 30px; width: 267px;"
          >
            <%= @seller.description %>
          </div>
          <div :if={@seller.location} class="is-size-6 mb-small has-dark-gray-text">
            <%= @seller.location %>
          </div>
          <div :for={url <- @user_urls} class="is-size-6" style="text-decoration: underline;">
            <.url_or url={url} />
          </div>
        </div>
      </div>
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

  defp url_or(assigns) do
    ~H"""

    """
  end

  defp right(assigns) do
    ~H"""
    <div style="padding-top: 150px; width: 100%; border-left: 1px solid #707070;">
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
end