defmodule PlazaWeb.CustomComponents do
  use Phoenix.Component

  def how_it_works_seller_mobile(assigns) do
    ~H"""
    <div style="display: flex; justify-content: center; background-color: #F8FC5F; position: fixed; top: 0; left: 0; bottom: 0; right: 0; z-index: 202;">
      <div
        class="has-font-3"
        style="display: flex; flex-direction: column; justify-content: center; text-align: center; margin-left: 10px; margin-right: 10px;"
      >
        <div style="font-size: 34px; line-height: 36px; text-decoration: underline;">
          Plaza para artistas não está
        </div>
        <div style="font-size: 34px; text-decoration: underline; margin-bottom: 50px;">
          disponível pelo celular
        </div>
        <div style="font-size: 20px; margin-bottom: 25px;">
          Monetize seus projetos com camisetas e posters.
        </div>
        <div style="font-size: 20px; line-height: 22px;">
          Crie sua loja e comece a vender hoje mesmo,
        </div>
        <div style="font-size: 20px; margin-bottom: 25px;">
          totalmente sem custos ou assinatura.
        </div>
        <div style="font-size: 20px; line-height: 22px;">
          A produção é feita sobre demanda uma a uma. sem
        </div>
        <div style="font-size: 20px; margin-bottom: 50px;">
          desperdícios e entregue direto para o cliente final.
        </div>
        <div style="font-size: 26px; line-height: 28px;">
          Acesse plazaaaaa.com em um
        </div>
        <div style="font-size: 26px; margin-bottom: 50px;">
          computador e crie sua loja
        </div>
        <div style="font-size: 20px; text-decoration: underline; margin-left: auto;">
          <.link navigate="/">
            voltar para loja
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
