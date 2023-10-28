defmodule PlazaWeb.UserLoginLive do
  use PlazaWeb, :live_view

  def render(assigns) do
    ~H"""
    <PlazaWeb.Auth.Login.login form={@form} />
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
end
