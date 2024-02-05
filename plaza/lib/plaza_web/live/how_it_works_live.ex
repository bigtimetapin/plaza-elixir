defmodule PlazaWeb.HowItWorksLive do
  use PlazaWeb, :live_view

  alias PlazaWeb.CustomComponents

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(%{live_action: :seller} = assigns) do
    ~H"""
    <div class="is-how-it-works-desktop">
      <div class="has-font-3" style="display: flex; justify-content: center;">
        <div style="display: flex; flex-direction: column; justify-content: center; width: 100%; max-width: 1100px; margin-top: 150px;">
          <div style="font-size: 38px; text-align: center; margin-bottom: 25px;">
            Como funciona para
          </div>
          <div style="display: flex; justify-content: center; margin-bottom: 25px;">
            <div style="font-size: 64px; text-decoration: underline; margin-right: 75px;">
              <.link navigate="/how-it-works/seller">
                CRIADORES
              </.link>
            </div>
            <div style="font-size: 64px; text-decoration: underline; color: lightgrey;">
              <.link navigate="/how-it-works/buyer" style="color: lightgrey;">
                COMPRADORES
              </.link>
            </div>
          </div>
          <div style="font-size: 24px; text-align: center; margin-bottom: 50px;">
            <div style="margin-bottom: 10px;">
              plaza é um espaço para criadores e artistas independentes.
            </div>
            <div style="line-height: 26px;">
              Oferecemos ferramentas para vender, fabricar e distribuir suas criações.
            </div>
            <div>
              Sem risco. Sem desperdício.
            </div>
          </div>
          <div style="display: flex; justify-content: center; margin-bottom: 15px;">
            <img src="/svg/big-arrow-down.svg" />
          </div>
          <div style="display: flex;">
            <div>
              <div style="display: flex; margin-bottom: 50px;">
                <div class="has-font-1" style="font-size: 62px; margin-right: 25px;">
                  01
                </div>
                <div style="width: 100%;">
                  <div style="font-size: 62px;">
                    Envie sua arte
                  </div>
                  <div style="font-size: 24px;">
                    <div style="line-height: 26px;">
                      Faça upload da sua arte e vamos começar a vender em minutos.
                    </div>
                    <div style="line-height: 26px;">
                      O upload deve ser de arquivos .png no tamanho A3
                    </div>
                  </div>
                </div>
              </div>
              <div style="display: flex; margin-bottom: 50px;">
                <div class="has-font-1" style="font-size: 62px; margin-right: 25px;">
                  02
                </div>
                <div style="width: 100%;">
                  <div style="font-size: 62px;">
                    Escolha o produto
                  </div>
                  <div style="font-size: 24px;">
                    <div style="line-height: 26px;">
                      Selecione a cor do tecido ou o tipo de
                    </div>
                    <div style="line-height: 26px;">
                      papel e defina o preço de venda.
                    </div>
                  </div>
                </div>
              </div>
              <div style="display: flex; margin-bottom: 50px;">
                <div class="has-font-1" style="font-size: 62px; margin-right: 25px;">
                  03
                </div>
                <div style="width: 100%;">
                  <div style="font-size: 62px;">
                    Compartilhe
                  </div>
                  <div style="font-size: 24px;">
                    <div style="line-height: 26px;">
                      Crie sua campanha de divulgação para atingir o maior
                    </div>
                    <div style="line-height: 26px;">
                      número de vendas antes do produto expirar, o prazo
                    </div>
                    <div style="line-height: 26px;">
                      máximo é de 45 dias.
                    </div>
                  </div>
                </div>
              </div>
              <div style="display: flex; margin-bottom: 50px;">
                <div class="has-font-1" style="font-size: 62px; margin-right: 25px;">
                  04
                </div>
                <div style="width: 100%;">
                  <div style="font-size: 62px;">
                    Nós vendemos e você recebe
                  </div>
                  <div style="font-size: 24px;">
                    <div style="line-height: 26px;">
                      Fabricamos todos os pedidos vendidos, e enviamos direto para os clientes.
                    </div>
                    <div style="line-height: 26px;">
                      Não tem limite para quanto você pode vender. Através da ferramenta de
                    </div>
                    <div style="line-height: 26px;">
                      pagamentos stripe você recebe e acompanha as finanças da sua loja.
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div style="margin-left: auto; display: flex; flex-direction: column;">
              <div style="margin-top: 50px; margin-bottom: 150px;">
                <img src="/svg/big-yellow-circle.svg" style="width: 250px;" />
              </div>
              <div>
                <img src="/svg/big-yellow-circle.svg" style="width: 250px;" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="is-how-it-works-mobile">
      <CustomComponents.how_it_works_seller_mobile />
    </div>
    """
  end

  def render(%{live_action: :buyer} = assigns) do
    ~H"""
    <div style="display: flex; justify-content: center; margin-top: 250px;">
      buyer
    </div>
    """
  end
end
