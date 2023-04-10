defmodule PlazaWeb.UploadLive do
  use PlazaWeb, :live_view

  alias Phoenix.Component
  alias Phoenix.HTML
  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormData

  alias Plaza.Products
  alias Plaza.Products.Product

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
      |> assign(:num_colors, 1)

    IO.inspect(socket)

    {:noreply, socket}
  end

  def handle_event("color", %{"color" => num_colors_as_string}, socket) do
    num_colors =
      case num_colors_as_string do
        "1" -> 1
        "2" -> 2
      end

    socket =
      socket
      |> assign(:num_colors, num_colors)

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
    IO.inspect(assigns)

    ~H"""
    <div style="margin-top: 200px;">
      <.body>
        <:center>
          <.two num_colors={@num_colors} />
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

  attr :num_colors, :integer, required: true

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
      </div>
      <.form>
        <input
          type="radio"
          name="num-color-radio-one"
          id="num-color-radio-one"
          phx-click="color"
          phx-value-color={1}
        />
        <label for="num-color-radio-one" class={if @num_colors == 1, do: "yellow", else: "white"}>
          <div class="has-text-centered">
            1
          </div>
        </label>
        <input
          type="radio"
          name="num-color-radio-two"
          id="num-color-radio-two"
          phx-click="color"
          phx-value-color={2}
        />
        <label for="num-color-radio-two" class={if @num_colors == 2, do: "yellow", else: "white"}>
          <div class="has-text-centered">
            2
          </div>
        </label>
      </.form>
    </div>
    """
  end
end
