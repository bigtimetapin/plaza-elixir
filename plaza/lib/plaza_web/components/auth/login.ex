defmodule PlazaWeb.Auth.Login do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: PlazaWeb.Endpoint,
    router: PlazaWeb.Router

  import PlazaWeb.CoreComponents

  def login_quick(assigns) do
    ~H"""
    <div>
      <.login form={@form} full={false} />
    </div>
    """
  end

  def login_full(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.login form={@form} />
    </div>
    """
  end

  attr :form, :any, required: true
  attr :full, :boolean, default: true

  def login(assigns) do
    ~H"""
    <.header :if={@full} class="text-center">
      Sign in to account
      <:subtitle>
        Don't have an account?
        <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
          Sign up
        </.link>
        for an account now.
      </:subtitle>
    </.header>

    <.simple_form
      for={@form}
      id="login_form"
      action={if @full, do: ~p"/users/log_in", else: ~p"/users/log_in_quick"}
      phx-update="ignore"
    >
      <.input field={@form[:email]} type="email" label="Email" required />
      <.input field={@form[:password]} type="password" label="Password" required />

      <:actions :if={@full}>
        <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
        <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
          Forgot your password?
        </.link>
      </:actions>
      <:actions>
        <.button phx-disable-with="Signing in..." class="w-full">
          Sign in <span aria-hidden="true">→</span>
        </.button>
      </:actions>
    </.simple_form>
    """
  end
end
