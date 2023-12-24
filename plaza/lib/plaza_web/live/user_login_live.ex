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
end
