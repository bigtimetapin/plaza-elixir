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
              Plaza é um espaço para criadores e artistas independentes.
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
              <div style="display: flex; margin-bottom: 75px;">
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
                    <div style="line-height: 26px; margin-bottom: 150px;">
                      pagamentos
                      <a href="https://stripe.com/en-br/connect" target="_blank">
                        <em style="text-decoration: underline;">stripe</em>
                      </a>
                      você recebe e acompanha as finanças da sua loja.
                    </div>
                    <div>
                      <.link navigate="/upload">
                        <img src="/svg/yellow-ellipse.svg" />
                        <div
                          class="has-font-3"
                          style="position: relative; bottom: 79px; left: 15px; font-size: 36px;"
                        >
                          Quero Vender
                        </div>
                      </.link>
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
    <div class="is-how-it-works-desktop">
      <div class="has-font-3" style="display: flex; justify-content: center;">
        <div style="display: flex; flex-direction: column; justify-content: center; width: 100%; max-width: 1100px; margin-top: 150px;">
          <div style="font-size: 38px; text-align: center; margin-bottom: 25px;">
            Como funciona para
          </div>
          <div style="display: flex; justify-content: center; margin-bottom: 25px;">
            <div style="font-size: 64px; text-decoration: underline; color: lightgrey; margin-right: 75px;">
              <.link navigate="/how-it-works/seller" style="color: lightgrey;">
                CRIADORES
              </.link>
            </div>
            <div style="font-size: 64px; text-decoration: underline;">
              <.link navigate="/how-it-works/buyer">
                COMPRADORES
              </.link>
            </div>
          </div>
          <div style="font-size: 28px; text-align: center; margin-bottom: 25px;">
            <div style="line-height: 30px;">
              Plaza é um marketplace de artistas originais,
            </div>
            <div style="line-height: 30px;">
              produtos impressos com qualidade e ética.
            </div>
          </div>
          <div style="font-size: 22px; text-align: center; margin-bottom: 50px;">
            <div style="line-height: 24px;">
              Mas não somos qualquer loja online, para minimizar o risco
            </div>
            <div style="line-height: 24px;">
              dos artistas e diminuir recursos desperdiçados produzimos
            </div>
            <div style="line-height: 24px;">
              apenas quantos produtos forem vendidos. On-demand.
            </div>
            <div style="line-height: 24px;">
              Um a um, sem quantidade mínima.
            </div>
          </div>
          <div style="display: flex; justify-content: center; margin-bottom: 25px;">
            <img src="/svg/big-arrow-down.svg" />
          </div>
          <div style="display: flex; align-self: center; margin-bottom: 100px;">
            <div class="has-font-1" style="font-size: 62px; margin-right: 25px;">
              01
            </div>
            <div>
              <div style="font-size: 62px;">
                Escolha seu produto
              </div>
              <div style="font-size: 24px;">
                <div style="line-height: 26px;">
                  Navegue na nossa loja e encontre seus designs favoritos.
                </div>
              </div>
            </div>
          </div>
          <div style="display: flex; align-self: center; margin-bottom: 25px;">
            <div class="has-font-1" style="font-size: 62px; margin-right: 25px;">
              02
            </div>
            <div style="margin-right: 50px;">
              <div style="font-size: 62px;">
                Adicione ao carrinho
              </div>
              <div style="font-size: 24px;">
                <div style="line-height: 26px;">
                  Prossiga para o pagamento e informações de entrega.
                </div>
              </div>
            </div>
            <div style="position: relative; bottom: 20px;">
              <img src="/svg/big-yellow-circle.svg" style="width: 225px;" />
            </div>
          </div>
          <div style="display: flex; align-self: center; margin-bottom: 150px;">
            <div class="has-font-1" style="font-size: 62px; margin-right: 25px;">
              03
            </div>
            <div style="width: 100%;">
              <div style="font-size: 62px;">
                Entregamos direto pra você
              </div>
              <div style="font-size: 24px;">
                <div style="line-height: 26px;">
                  Fique de olho no seu email para atualizações e espere seu pedido em casa.
                </div>
              </div>
            </div>
          </div>
          <div style="display: flex; align-self: center; margin-bottom: 100px;">
            <.link navigate="/">
              <img src="/svg/yellow-ellipse.svg" />
              <div
                class="has-font-3"
                style="position: relative; bottom: 79px; left: 15px; font-size: 34px;"
              >
                Voltar para loja
              </div>
            </.link>
          </div>
        </div>
      </div>
    </div>
    <div class="is-how-it-works-mobile">
      <CustomComponents.how_it_works_seller_mobile />
    </div>
    """
  end
end
