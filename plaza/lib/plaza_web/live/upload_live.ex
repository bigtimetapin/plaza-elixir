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
      |> assign(:num_colors, 1)

    {:noreply, socket}
  end

  def handle_event("color", %{"color" => num_colors_as_string}, socket) do
    num_colors =
      case num_colors_as_string do
        "1" -> 1
        "2" -> 2
        "3" -> 3
        "4" -> 4
        "5" -> 5
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
      <.num_color_input num_colors={@num_colors} color={1} />
      <.num_color_input num_colors={@num_colors} color={2} />
      <.num_color_input num_colors={@num_colors} color={3} />
      <.num_color_input num_colors={@num_colors} color={4} />
      <.num_color_input num_colors={@num_colors} color={5} />
    </div>
    """
  end

  attr :color, :integer, required: true
  attr :num_colors, :integer, required: true

  defp num_color_input(assigns) do
    ~H"""
    <input
      style="width: 0;"
      type="radio"
      name={num_color_input_id(assigns.color)}
      id={num_color_input_id(assigns.color)}
      phx-click="color"
      phx-value-color={@color}
    />
    <label
      for={num_color_input_id(assigns.color)}
      class={if @color == @num_colors, do: "yellow", else: "white"}
    >
      <div class="has-text-centered" style="position: relative; top: -6px;">
        <%= @color %>
      </div>
    </label>
    """
  end

  defp num_color_input_id(color) do
    "num-color-radio-#{color}"
  end
end
