defmodule PlazaWeb.UploadLive do
  use PlazaWeb, :live_view

  alias PlazaWeb.ProductComponent

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

  def handle_event("step", %{"step" => "3"}, socket) do
    socket =
      socket
      |> assign(:step, 3)
      |> assign(:product_type, 1)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "4"}, socket) do
    socket =
      socket
      |> assign(:step, 4)
      |> assign(:num_expected, 50)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "5"}, socket) do
    IO.inspect(socket)

    socket =
      socket
      |> assign(:step, 5)
      |> assign(:name, nil)
      |> assign(:descr_short, nil)
      |> assign(:descr_long, nil)

    {:noreply, socket}
  end

  def handle_event("color", %{"color" => num_colors_as_string}, socket) do
    num_colors = String.to_integer(num_colors_as_string)

    socket =
      socket
      |> assign(:num_colors, num_colors)

    {:noreply, socket}
  end

  def handle_event("product", %{"product" => product_type_as_string}, socket) do
    product_type = String.to_integer(product_type_as_string)

    socket =
      socket
      |> assign(:product_type, product_type)

    {:noreply, socket}
  end

  def handle_event("num-expected-change", %{"num-expected" => num_expected_as_string}, socket) do
    num_expected =
      case num_expected_as_string do
        "" -> 0
        nes -> String.to_integer(nes)
      end

    socket =
      case num_expected >= 0 do
        true ->
          socket
          |> assign(:num_expected, num_expected)

        false ->
          socket
      end

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

  def render(%{step: 3} = assigns) do
    ~H"""
    <div class="is-size-8 mx-large" style="margin-top: 200px;">
      <div class="columns">
        <div class="column is-3">
          <ProductComponent.selectable
            selected={@product_type == 1}
            product={product_type(1)}
            phx-click="product"
            phx-value-product={1}
          />
        </div>

        <div class="column is-3">
          <ProductComponent.selectable
            selected={@product_type == 2}
            product={product_type(2)}
            phx-click="product"
            phx-value-product={2}
          />
        </div>
        <div class="column is-3">
          <ProductComponent.selectable
            selected={@product_type == 3}
            product={product_type(3)}
            phx-click="product"
            phx-value-product={3}
          />
        </div>
        <div class="column is-3">
          <ProductComponent.selectable
            selected={@product_type == 4}
            product={product_type(4)}
            phx-click="product"
            phx-value-product={4}
          />
        </div>
      </div>
      <div class="mt-xlarge" style="display: flex; justify-content: flex-end;">
        <.next_button phx-value-step="4" />
      </div>
    </div>
    """
  end

  def render(%{step: 4} = assigns) do
    ~H"""
    <div class="mx-large has-font-3 is-size-8" style="margin-top: 200px;">
      <div style="display: inline-block;">
        <ProductComponent.product product={product_type(@product_type)} />
      </div>
      <div style="display: inline-block; position: relative; left: 100px;">
        <div class="mb-small">
          <div style="display: inline-block; position: relative; right: 15px;">
            Defina sua margem de lucro por unidade
          </div>
          <div style="display: inline-block;">
            <div style="width: 120px; height: 60px; border: 1px solid gray; display: flex; justify-content: center; align-items: center;">
              15 reais
            </div>
          </div>
        </div>
        <div style="display: flex; justify-content: flex-end;">
          <div style="display: inline-block; position: relative; right: 25px;">
            Quantas unidades você espera vender
          </div>
          <div style="display: inline-block;">
            <form phx-change="num-expected-change" onkeydown="return event.key != 'Enter';">
              <input
                type="number"
                name="num-expected"
                value={@num_expected}
                style="width: 120px; height: 60px; border: 1px solid gray; display: flex; justify-content: center; align-items: center;"
                class="has-font-3 is-size-8"
              />
            </form>
          </div>
        </div>
      </div>
      <div style="display: inline-block; position: relative; left: 200px; top: 100px;">
        <div style="text-align: center;">
          Seu lucro:
        </div>
        <div
          class="has-yellow"
          style="width: 200px; height: 140px; border: 1px solid gray; border-radius: 100px; display: flex; justify-content: center; align-items: center; font-size: 50px;"
        >
          <%= @num_expected * 15 %> reais
        </div>
        <div style="position: relative; top: 150px; left: 100px;">
          <.next_button phx-value-step="5" />
        </div>
      </div>
    </div>
    """
  end

  def render(%{step: 5} = assigns) do
    ~H"""
    <div class="mx-large has-font-3 is-size-8" style="margin-top: 200px;">
      <div style="display: inline-block; position: relative; left: 100px;">
        <ProductComponent.product product={product_type(@product_type)} />
      </div>
      <div style="display: inline-block; position: relative; left: 200px;">
        <div class="mb-medium">
          <div style="display: inline-block;">
            logo (opcional)
          </div>
          <div style="display: inline-block;">
            <form>
              <input
                name="logo"
                class="has-font-3"
                style="width: 150px; height: 45px; border: 1px solid gray; text-align: center; font-size: 22px;"
                placeholder="upload"
                disabled
              />
            </form>
          </div>
        </div>
        <div>
          <div style="display: inline-block;">
            nome do produto
          </div>
          <div style="display: inline-block;">
            <form>
              <input
                type="text"
                name="product-name"
                class="has-font-3"
                style="width: 300px; height: 45px; border: 1px solid gray; text-align: center; font-size: 22px;"
              />
            </form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  slot :center, required: true

  defp body(assigns) do
    ~H"""
    <div class="columns">
      <div class="column is-3"></div>
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
    <div class="columns">
      <div class="column is-6">
        <div style="width: 750px; height: 300px; border: 2px solid gray;" class="mb-medium">
          <div style="display: flex; justify-content: center; align-items: center; height: 100%;">
            arquivo enviado arte101.png
          </div>
        </div>
        <div style="width: 750px; height: 300px; border: 2px solid gray;">
          <div style="display: flex; justify-content: center; align-items: center; height: 100%;">
            <div class="columns" style="width: 100%;">
              <div class="column is-7" style="text-align: center;">
                quantas cores tem sua estampa?
              </div>
              <div class="column is-5" style="position: relative; top: 5px;">
                <.num_color_input num_colors={@num_colors} color={1} />
                <.num_color_input
                  num_colors={@num_colors}
                  color={2}
                  style="position: relative; right: 10px;"
                />
                <.num_color_input
                  num_colors={@num_colors}
                  color={3}
                  style="position: relative; right: 20px;"
                />
                <.num_color_input
                  num_colors={@num_colors}
                  color={4}
                  style="position: relative; right: 30px;"
                />
                <.num_color_input
                  num_colors={@num_colors}
                  color={5}
                  style="position: relative; right: 40px;"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="column is-6 has-font-3 is-size-8" style="display: flex; justify-content: center;">
        <div style="position: relative; height: 100%;">
          <div style="position: absolute; top: 50px; width: 250px;">
            <div class="mb-xsmall">
              dúvidas
            </div>
            <div>
              baixar modelo .pdf
            </div>
          </div>
          <div style="position: absolute; bottom: 50px;">
            <.next_button phx-value-step="3" />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :rest, :global

  defp next_button(assigns) do
    ~H"""
    <button phx-click="step" {@rest}>
      <div
        style="width: 200px; height: 100px; border-radius: 200px; border: 1px solid gray;"
        class="has-yellow"
      >
        <div style="display: flex; justify-content: center; align-items: center; height: 100%;">
          próximo
        </div>
      </div>
    </button>
    """
  end

  attr :color, :integer, required: true
  attr :num_colors, :integer, required: true
  attr :rest, :global

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
      {@rest}
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

  defp product_type(int) do
    case int do
      1 -> %{name: "camiseta 1", price: 30}
      2 -> %{name: "camiseta 2", price: 40}
      3 -> %{name: "camiseta 3", price: 50}
      4 -> %{name: "boné ", price: 45}
    end
  end
end
