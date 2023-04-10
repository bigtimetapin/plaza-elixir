defmodule PlazaWeb.UploadLive do
  use PlazaWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Upload")
      |> assign(:header, :upload)
      |> assign(:step, 1)

    {:ok, socket}
  end

  def handle_event("step", %{"step" => "2"}, socket) do
    socket =
      socket
      |> assign(:step, 2)

    {:noreply, socket}
  end

  def render(%{step: 1} = assigns) do
    ~H"""
    <.body>
      <:center>
        <.one />
      </:center>
    </.body>
    """
  end

  def render(%{step: 2} = assigns) do
    ~H"""
    <div style="margin-top: 200px;">
      <.body>
        <:center>
          <.two />
        </:center>
      </.body>
    </div>
    """
  end

  slot :center, required: true
  attr :rest, :global

  defp body(assigns) do
    ~H"""
    <div class="columns">
      <div class="column is-2"></div>
      <div class="column has-font-3 is-size-8">
        <%= render_slot(@center) %>
      </div>
    </div>
    """
  end

  defp one(assigns) do
    ~H"""
    <div>
      <button
        style="width: 750px; height: 300px; border: 2px solid gray;"
        phx-click="step"
        phx-value-step="2"
        class="has-font-3"
      >
        arraste seu arquivo aqui
      </button>
    </div>
    """
  end

  defp two(assigns) do
    ~H"""
    <div>
      <div style="width: 750px; height: 300px; border: 2px solid gray;" class="mb-medium">
        <div style="display: flex; justify-content: center; align-items: center; height: 100%;">
          arquivo enviado arte101.png
        </div>
      </div>
      <div style="width: 750px; height: 300px; border: 2px solid gray;">
        <div style="display: flex; justify-content: center; align-items: center; height: 100%;">
          quantas cores tem sua estampa?
        </div>

        <form>
          <h1>Custom Radio Buttons</h1>
          <label class="plaza-radio-container">
            One <input type="radio" checked="checked" name="radio" />
            <span class="plaza-radio"></span>
          </label>
          <label class="plaza-radio-container">
            Two <input type="radio" name="radio" />
            <span class="plaza-radio"></span>
          </label>
          <label class="plaza-radio-container">
            Three <input type="radio" name="radio" />
            <span class="plaza-radio"></span>
          </label>
          <label class="plaza-radio-container">
            Four <input type="radio" name="radio" />
            <span class="plaza-radio"></span>
          </label>
        </form>
      </div>
    </div>
    """
  end
end
