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
    <div style="margin-top: 200px; margin-bottom: 200px; display: flex; justify-content: center;">
      <img src="gif/loading.gif" class="is-loading" />
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
    <div class="is-artist-page-desktop">
      <div style="display: flex; justify-content: center;">
        <div style="display: flex; max-width: 1750px; width: 100%; margin-right: 10px;">
          <.left seller={@seller} />
          <.right products={@products} all_products={@all_products} />
        </div>
      </div>
    </div>
    <div class="is-artist-page-mobile has-font-3" style="margin-top: 50px;">
      <div style="display: flex; margin-left: 20px; margin-right: 20px;">
        <div style="display: flex; flex-direction: column; width: 100%;">
          <div style="width: 202px; height: 202px; background: lightgrey; overflow: hidden; margin-bottom: 17px; align-self: center;">
            <img
              :if={@seller.profile_photo_url}
              src={@seller.profile_photo_url}
              style="min-width: 100%; min-height: 100%; border: 1px dotted lightgrey;"
            />
          </div>
          <div style="font-size: 32px; text-align: center; margin-bottom: 18px;">
            <%= @seller.user_name %>
          </div>
          <div style="font-size: 22px; text-align: center; width: 200px; align-self: center; margin-bottom: 8px;">
            <%= @seller.description %>
          </div>
          <div style="font-size: 20px; text-decoration: underline; text-align: center; margin-bottom: 73px;">
            <.urls_mobile seller={@seller} />
          </div>
          <div
            :for={product <- @products}
            style="margin-bottom: 150px; margin-left: 5px; margin-right: 5px;"
          >
            <ProductComponent.product product={product} meta={true} disabled={false} />
          </div>
          <div
            :if={!@all_products && Enum.count(@products) == 3}
            style="text-align: center; font-size: 24px;"
          >
            <button class="has-font-3" phx-click="all-products" style="text-decoration: underline;">
              Ver todos os produtos
            </button>
          </div>
          <div style="margin-bottom: 250px;"></div>
        </div>
      </div>
    </div>
    """
  end

  defp urls_mobile(assigns) do
    seller = assigns.seller

    website =
      case seller.website do
        nil ->
          nil

        nn ->
          {:url, nn}
      end

    instagram =
      case seller.socials.instagram do
        nil ->
          nil

        nn ->
          {:url, nn}
      end

    twitter =
      case seller.socials.twitter do
        nil ->
          nil

        nn ->
          {:url, nn}
      end

    soundcloud =
      case seller.socials.soundcloud do
        nil ->
          nil

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
      |> assign(urls: urls)

    ~H"""
    <div :for={url <- @urls}>
      <.url_or url={url} />
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
    <div class="has-font-3">
      <div style="width: 377px; height: 377px; overflow: hidden; border-bottom: 1px solid grey;">
        <img
          src={if @seller.profile_photo_url, do: @seller.profile_photo_url, else: "png/pep.png"}
          style="min-width: 100%; min-height: 100%;"
        />
      </div>
      <div style="display: flex; flex-direction: column;">
        <div style="margin-left: 25px; margin-top: 10px; height: 600px;">
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
    <div style="padding-top: 75px; width: 100%; border-left: 1px solid #707070;">
      <div style="margin-left: 75px; margin-bottom: 75px">
        <ProductComponent.products3 products={@products} />
      </div>
      <div
        :if={!@all_products && Enum.count(@products) == 3}
        style="display: flex; justify-content: center; margin-bottom: 200px;"
      >
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
