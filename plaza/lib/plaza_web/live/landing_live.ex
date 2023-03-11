defmodule PlazaWeb.LandingLive do
  use PlazaWeb, :live_view

  def mount(params, session, socket) do
    {:ok, assign(socket, :page_title, "Plaza Hello")}
  end

end
