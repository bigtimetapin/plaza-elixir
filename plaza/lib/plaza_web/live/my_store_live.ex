defmodule PlazaWeb.MyStoreLive do
  use PlazaWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(header: :my_store)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <div class="has-font-3" style="display: inline-block;">
        <div class="mb-xsmall">
          <img src="images/pep.png" style="width: 377px;" />
        </div>
        <div style="position: relative; left: 61px; width: 316px; border-right: 1px solid gray;">
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
    </div>
    """
  end
end
