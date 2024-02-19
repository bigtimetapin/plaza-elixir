defmodule PlazaWeb.MobileFooter do
  use Phoenix.Component
  import PlazaWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <div class="has-font-3" style="display: flex; justify-content: center;">
      <div style="margin-left: 10px; margin-right: 10px; margin-top: 50px;">
        <div style="font-size: 32px; text-align: center;" class="has-font-1">
          Conta
        </div>
        <div style="text-decoration: underline; text-align: center; font-size: 28px; margin-bottom: 50px;">
          <.link navigate="/my-account">
            Acessar Conta
          </.link>
        </div>
        <div style="font-size: 32px; text-align: center;" class="has-font-1">
          Sobre
        </div>
        <div style="text-decoration: underline; text-align: center; font-size: 28px; margin-bottom: 50px;">
          <a href="mailto:admin@plazaaaaa.com">
            Contato
          </a>
        </div>
        <div style="display: flex; justify-content: center; margin-bottom: 100px;">
          <img src="/svg/footer-left-02.svg" />
        </div>
        <div style="font-size: 22px; line-height: 24px; display: flex; justify-content: center; margin-bottom: 100px;">
          <div style="width: 325px; ">
            Plaza é uma plataforma de integração de serviços e pagamentos automatizados para artistas e criadores,
            entre em contato para saber mais, trabalhar conosco ou qualquer dúvida.
            <a style="text-decoration: underline;" href="mailto:admin@plazaaaaa.com">
              CONTATO
            </a>
          </div>
        </div>
        <div style="margin-bottom: 100px;">
          <img src="/svg/footer-right-02.svg" />
        </div>
      </div>
    </div>
    """
  end
end
