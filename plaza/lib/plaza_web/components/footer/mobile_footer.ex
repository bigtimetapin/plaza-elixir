defmodule PlazaWeb.MobileFooter do
  use Phoenix.Component
  import PlazaWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <div class="has-font-3" style="display: flex; justify-content: center;">
      <div style="margin-left: 10px; margin-right: 10px; margin-top: 75px;">
        <div style="font-size: 30px; text-align: center; margin-bottom: 17px;" class="has-font-1">
          Conta
        </div>
        <div style="text-decoration: underline; text-align: center; font-size: 26px; margin-bottom: 49px;">
          <.link navigate="/my-account">
            Acessar Conta
          </.link>
        </div>
        <div style="font-size: 30px; text-align: center; margin-bottom: 17px;" class="has-font-1">
          Sobre
        </div>
        <div style="text-decoration: underline; text-align: center; font-size: 26px; margin-bottom: 49px;">
          <a href="mailto:admin@plazaaaaa.com">
            Contato
          </a>
        </div>
        <div style="display: flex; justify-content: center; margin-bottom: 71px; margin-left: 20px; margin-right: 20px;">
          <img src="/svg/footer-left-02.svg" />
        </div>
        <div style="display: flex; justify-content: center; margin-bottom: 55px; margin-left: 10px;">
          <div style="font-size: 22px; line-height: 24px; ">
            <div>
              Plaza é uma plataforma de integração de
            </div>
            <div>
              serviços e pagamentos automatizados para
            </div>
            <div>
              artistas e criadores, entre em contato para
            </div>
            <div>
              saber mais, trabalhar conosco ou qualquer
            </div>
            <div>
              dúvida.
              <a style="text-decoration: underline;" href="mailto:admin@plazaaaaa.com">CONTATO</a>
            </div>
          </div>
        </div>
        <div style="margin-bottom: 75px; display: flex; justify-content: center; margin-right: 30px;">
          <img src="/svg/footer-right-02.svg" />
        </div>
      </div>
    </div>
    """
  end
end
