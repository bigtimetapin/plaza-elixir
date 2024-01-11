defmodule PlazaWeb.UserLoginLive do
  use PlazaWeb, :live_view

  def render(assigns) do
    ~H"""
    <div style="margin-top: 150px; margin-bottom: 150px;">
      <PlazaWeb.Auth.Login.login_full form={@form} />
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    socket =
      socket
      |> assign(:form, form)
      |> assign(:header, :login)

    {:ok, socket, temporary_assigns: [form: form]}
  end

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
end
