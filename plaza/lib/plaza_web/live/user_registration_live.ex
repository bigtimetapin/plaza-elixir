defmodule PlazaWeb.UserRegistrationLive do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias Plaza.Accounts.User

  def render(assigns) do
    ~H"""
    <div style="margin-top: 150px; margin-bottom: 150px; margin-left: 10px; margin-right: 10px;">
      <div class="has-font-3" style="display: flex; justify-content: center;">
        <div style="display: flex; flex-direction: column; width: 380px;">
          <div style="border-bottom: 1px solid grey; margin-bottom: 25px;">
            <div style="margin-left: 10px; font-size: 34px; line-height: 40px;">
              Criar Conta
            </div>
          </div>
          <div>
            <.simple_form
              for={@form}
              id="registration_form"
              phx-submit="save"
              phx-change="validate"
              phx-trigger-action={@trigger_submit}
              action={~p"/users/log_in?_action=registered"}
              method="post"
            >
              <div style="margin-left: 10px; font-size: 22px;">
                email
              </div>
              <.input
                field={@form[:email]}
                type="email"
                label="Email"
                required
                style="border-bottom: 2px solid grey; font-size: 28px; width: 100%; background: #F8FC5F; margin-bottom: 25px;"
                class="has-font-3"
                placeholder="seu email"
              />
              <div style="margin-left: 10px; font-size: 22px;">
                password
              </div>
              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                required
                style="border-bottom: 2px solid grey; font-size: 28px; width: 100%; background: #F8FC5F; margin-bottom: 50px;"
                class="has-font-3"
                placeholder="senha"
              />
              <div style="display: flex;">
                <div style="margin-left: auto;">
                  <button phx-disable-with="criando...">
                    <img src="/svg/yellow-ellipse.svg" />
                    <div class="has-font-3" style="position: relative; bottom: 79px; font-size: 36px;">
                      criar conta
                    </div>
                  </button>
                </div>
              </div>
            </.simple_form>
          </div>
          <div style="display: flex; font-size: 20px;">
            <div style="margin-left: auto; margin-right: 20px;">
              <div style="display: flex;">
                <div>
                  <%= "Já tenho uma conta >>" %>
                </div>
                <div style="margin-left: 3px;">
                  <.link navigate={~p"/users/log_in"} style="text-decoration: underline;">
                    Acessar
                  </.link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign(:header, :login)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
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

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
