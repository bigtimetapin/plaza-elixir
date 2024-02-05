defmodule PlazaWeb.HowItWorksLive do
  use PlazaWeb, :live_view

  alias PlazaWeb.CustomComponents

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(%{live_action: :seller} = assigns) do
    ~H"""
    <div class="is-how-it-works-desktop"></div>
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
