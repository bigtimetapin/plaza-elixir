defmodule PlazaWeb.DesktopFooter do
  use Phoenix.LiveComponent
  import PlazaWeb.CoreComponents

  alias Plaza.Accounts
  alias Plaza.Accounts.UserNotifier

  @impl true
  def update(_assigns, socket) do
    socket =
      socket
      |> assign(
        email_form:
          to_form(
            %{
              "email" => nil
            },
            as: "email-form"
          )
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("change-email-form", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("submit-email-form", %{"email-form" => %{"email" => email}}, socket) do
    case Accounts.get_email(email) do
      nil ->
        case Accounts.set_email(email) do
          {:ok, _} ->
            UserNotifier.deliver_newsletter_registration(email)

          _ ->
            nil
        end

      _ ->
        nil
    end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div style="display: flex; justify-content: center;">
      <div style="display: flex;">
        <div style="margin-right: 20px;">
          <img src="/svg/footer-left.svg" />
        </div>
        <div>
          <div>
            <img src="/svg/footer-right.svg" />
          </div>
          <div
            class="has-font-3 is-footer-desktop-left"
            style="position: relative; bottom: min(29vw, 465px); height: 0px;"
          >
            <div style="display: flex; margin-left: 40px; margin-right: 40px;">
              <div style="width: 50%;">
                <div style="width: min(26vw, 510px);">
                  <div style="font-size: min(2.6vw, 52px); line-height: min(2.7vw, 54px); margin-bottom: 10px;">
                    Inscreva-se e receba todas as novidades da comunidade!
                  </div>
                  <div style="font-size: min(1.1vw, 22px); line-height: min(1.1vw, 24px); margin-bottom: 20px;">
                    Atualmente é obrigatório possuir uma conta bancária no Brasil para abrir sua loja no Plaza. Em
                    breve mais países serão adicionados
                    <span style="text-decoration: underline;">increva-se para ser avisado</span>
                    desta e mais novidades.
                  </div>
                  <div style="margin-bottom: min(5.7vw, 110px);">
                    <.form
                      for={@email_form}
                      phx-change="change-email-form"
                      phx-submit="submit-email-form"
                      phx-target={@myself}
                    >
                      <div style="display: flex;">
                        <div style="width: 100%;">
                          <.input
                            field={@email_form[:email]}
                            type="text"
                            placeholder="seu email"
                            autocomplete="email"
                            style="width: 100%"
                          />
                        </div>
                        <div style="width: 0%; margin-left: auto; position: relative; right: 65px; align-self: center;">
                          <.button style="text-decoration: underline;" phx-disable-with=".........">
                            enviar
                          </.button>
                        </div>
                      </div>
                    </.form>
                  </div>
                  <div style="font-size: min(1.1vw, 22px); line-height: min(1.1vw, 24px);">
                    Plaza é uma plataforma de integração de serviços e pagamentos automatizados para artistas e criadores,
                    entre em contato para saber mais, trabalhar conosco ou qualquer dúvida.
                    <a style="text-decoration: underline;" href="mailto:admin@plazaaaaa.com">
                      CONTATO
                    </a>
                  </div>
                </div>
              </div>
              <div style="width: 50%">
                <div style="display: flex; margin-bottom: min(7vw, 125px);">
                  <div style="margin-right: 2.5vw;">
                    <div style="font-size: min(1.7vw, 30px);" class="has-font-1">
                      Comprando
                    </div>
                    <div style="text-decoration: underline; font-size: min(1.4vw, 26px);">
                      <.link navigate="/how-it-works/buyer">
                        Como funciona
                      </.link>
                    </div>
                  </div>
                  <div style="margin-right: 2.5vw;">
                    <div style="font-size: min(1.7vw, 30px);" class="has-font-1">
                      Vendendo
                    </div>
                    <div style="text-decoration: underline; font-size: min(1.4vw, 26px);">
                      <.link navigate="/how-it-works/seller">
                        Como funciona
                      </.link>
                    </div>
                    <div style="text-decoration: underline; font-size: min(1.4vw, 26px);">
                      <.link navigate="/how-it-works/seller">
                        Quero Vender
                      </.link>
                    </div>
                  </div>
                  <div style="margin-right: 2.5vw;">
                    <div style="font-size: min(1.7vw, 30px);" class="has-font-1">
                      Conta
                    </div>
                    <div style="text-decoration: underline; font-size: min(1.4vw, 26px);">
                      <.link navigate="/my-account">
                        Acessar Conta
                      </.link>
                    </div>
                  </div>
                  <div>
                    <div style="font-size: min(1.7vw, 30px);" class="has-font-1">
                      Sobre
                    </div>
                    <div style="text-decoration: underline; font-size: min(1.4vw, 26px);">
                      <a href="mailto:admin@plazaaaaa.com">
                        Contato
                      </a>
                    </div>
                  </div>
                </div>
                <div>
                  <img src="/svg/footer-right-icons.svg" />
                </div>
              </div>
            </div>
          </div>
          <div
            class="has-font-3 is-footer-desktop-right"
            style="position: relative; bottom: 28vw; height: 0px; margin-left: 40px;"
          >
            <div style="display: flex;">
              <div style="width: 50%;">
                <div style="display: flex; margin-bottom: 2vw;">
                  <div style="margin-right: 25px;">
                    <div style="font-size: 2.9vw;" class="has-font-1">
                      Comprando
                    </div>
                    <div style="text-decoration: underline; font-size: 2.4vw;">
                      <.link navigate="/how-it-works/buyer">
                        Como funciona
                      </.link>
                    </div>
                  </div>
                  <div>
                    <div style="font-size: 2.9vw;" class="has-font-1">
                      Vendendo
                    </div>
                    <div style="text-decoration: underline; font-size: 2.4vw;">
                      <.link navigate="/how-it-works/seller">
                        Como funciona
                      </.link>
                    </div>
                    <div style="text-decoration: underline; font-size: 2.4vw;">
                      <.link navigate="/how-it-works/seller">
                        Quero Vender
                      </.link>
                    </div>
                  </div>
                </div>
                <div style="display: flex;">
                  <div style="margin-right: 34px;">
                    <div style="font-size: 2.9vw;" class="has-font-1">
                      Conta
                    </div>
                    <div style="text-decoration: underline; font-size: 2.4vw;">
                      <.link navigate="/my-account">
                        Acessar Conta
                      </.link>
                    </div>
                  </div>
                  <div>
                    <div style="font-size: 2.9vw;" class="has-font-1">
                      Sobre
                    </div>
                    <div style="text-decoration: underline; font-size: 2.4vw;">
                      <a href="mailto:admin@plazaaaaa.com">
                        Contato
                      </a>
                    </div>
                  </div>
                </div>
              </div>
              <div style="width: 50%;">
                <div style="display: flex; justify-content: center;">
                  <img src="/svg/ssl.svg" />
                </div>
                <div style="display: flex; justify-content: center; margin-bottom: 1vw;">
                  <img src="/svg/dimona.svg" style="margin-right: 23px;" />
                  <img src="/svg/stripe.svg" />
                  <img src="/svg/mc.svg" />
                </div>
                <div style="display: flex; justify-content: center;">
                  <img src="/svg/visa.svg" style="margin-right: 23px;" />
                  <img src="/svg/ap.svg" style="margin-right: 23px;" />
                  <img src="/svg/gp.svg" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
