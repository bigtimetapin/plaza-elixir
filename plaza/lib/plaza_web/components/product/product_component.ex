defmodule PlazaWeb.ProductComponent do
  use Phoenix.Component

  embed_templates "./*"

  def product(assigns) do
    ~H"""
    <.product_component products={assigns.products}/>
    """
  end

end
