defmodule PlazaWeb.Auth.Login do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: PlazaWeb.Endpoint,
    router: PlazaWeb.Router

  import PlazaWeb.CoreComponents

  def login_quick(assigns) do
    ~H"""
    <div>
      <.login form={@form} full={false} button_right={@button_right} width={@width} />
    </div>
    """
  end

  def login_full(assigns) do
    ~H"""
    <div>
      <.login form={@form} width={@width} />
    </div>
    """
  end

  attr :form, :any, required: true
  attr :full, :boolean, default: true
  attr :button_right, :boolean, default: true
  attr :width, :integer, required: true

  def login(assigns) do
    ~H"""
    <div class="has-font-3" style="display: flex; justify-content: center;">
      <div style={"display: flex; flex-direction: column; width: #{@width}px;"}>
        <div :if={@full} style="border-bottom: 1px solid grey; margin-bottom: 25px;">
          <div style="margin-left: 10px; font-size: 34px; line-height: 40px;">
            Acessar Conta
          </div>
        </div>
        <div>
          <.simple_form
            for={@form}
            id="login_form"
            action={if @full, do: ~p"/users/log_in", else: ~p"/users/log_in_quick"}
            phx-update="ignore"
          >
            <div :if={@full} style="margin-left: 10px; font-size: 22px;">
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
            <div :if={@full} style="margin-left: 10px; font-size: 22px;">
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
            <.input :if={!@full} field={@form[:redirect_url]} style="display: none;" />
            <div :if={@button_right} style="display: flex;">
              <div style="margin-left: auto;">
                <button phx-disable-with="signing in...">
                  <img src="/svg/yellow-ellipse.svg" />
                  <div class="has-font-3" style="position: relative; bottom: 79px; font-size: 36px;">
                    accesar
                  </div>
                </button>
              </div>
            </div>
            <div :if={!@button_right} style="display: flex; justify-content: center;">
              <div>
                <button phx-disable-with="signing in...">
                  <img src="/svg/yellow-ellipse.svg" />
                  <div class="has-font-3" style="position: relative; bottom: 79px; font-size: 36px;">
                    accesar
                  </div>
                </button>
              </div>
            </div>
          </.simple_form>
        </div>
        <div :if={@full} style="display: flex; font-size: 20px;">
          <div style="margin-left: auto; margin-right: 20px;">
            <div style="display: flex;">
              <div>
                <%= "Ainda não tenho conta >>" %>
              </div>
              <div style="margin-left: 3px;">
                <.link navigate={~p"/users/register"} style="text-decoration: underline;">
                  Criar Conta
                </.link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  ## defp forget_your_password(assigns) do
  ##   ~H"""
  ##   <div>
  ##     <:actions :if={@full}>
  ##       <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
  ##       <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
  ##         Forgot your password?
  ##       </.link>
  ##     </:actions>
  ##   </div>
  ##   """
  ## end
end
