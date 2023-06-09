defmodule PlazaWeb.UploadLive do
  use PlazaWeb, :live_view

  alias Plaza.Products
  alias PlazaWeb.ProductComponent

  alias ExAws
  alias ExAws.S3

  @aws_s3_region "us-west-2"
  @aws_s3_bucket "plaza-static-dev"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Upload")
      |> assign(:header, :upload)
      |> assign(:design_url, nil)
      |> allow_upload(:design, accept: ~w(.jpg .jpeg .png), max_entries: 1)
      |> allow_upload(:logo, accept: ~w(.jpg .jpeg .png), max_entries: 1)
      |> assign(:step, 1)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:step, msg}, socket) do
    socket =
      case msg do
        2 ->
          socket
          |> assign(:step, 2)
          |> assign(:num_colors, 1)

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_info({:upload_design, {file_name, src}}, socket) do
    request =
      S3.put_object(
        @aws_s3_bucket,
        file_name,
        File.read!(src)
      )

    ExAws.request!(
      request,
      region: @aws_s3_region
    )

    design_url = "https://#{@aws_s3_bucket}.s3.us-west-2.amazonaws.com/#{file_name}"

    socket =
      socket
      |> assign(design_url: design_url)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
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
    socket =
      socket
      |> assign(:step, 5)
      |> assign(:name, nil)
      |> assign(:descr_short, nil)
      |> assign(:descr_long, nil)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "submit"}, socket) do
    Products.create_product(%{
      descr_long: socket.assigns.descr_long,
      descr_short: socket.assigns.descr_short,
      name: socket.assigns.name,
      num_colors: socket.assigns.num_colors,
      num_expected: socket.assigns.num_expected,
      product_type: socket.assigns.product_type,
      design_url: socket.assigns.design_url,
      user_id: socket.assigns.current_user.id
    })

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

  def handle_event("product-name-change", %{"product-name" => name}, socket) do
    socket =
      socket
      |> assign(:name, name)

    {:noreply, socket}
  end

  def handle_event("descr-short-change", %{"descr-short" => descr_short}, socket) do
    socket =
      socket
      |> assign(:descr_short, descr_short)

    {:noreply, socket}
  end

  def handle_event("descr-long-change", %{"descr-long" => descr_long}, socket) do
    socket =
      socket
      |> assign(:descr_long, descr_long)

    {:noreply, socket}
  end

  def handle_event("design-upload-change", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("design-upload-save", _params, socket) do
    [tup | []] =
      consume_uploaded_entries(socket, :design, fn %{path: path}, entry ->
        unique_file_name = "#{entry.uuid}-#{entry.client_name}"

        dest =
          Path.join([
            :code.priv_dir(:plaza),
            "static",
            "uploads",
            unique_file_name
          ])

        File.cp!(path, dest)
        {:ok, {"uploads/#{unique_file_name}", dest}}
      end)

    send(self(), {:step, 2})
    send(self(), {:upload_design, tup})

    {:noreply, socket}
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  @impl Phoenix.LiveView
  def render(%{step: 1} = assigns) do
    ~H"""
    <.body>
      <:center>
        <.one uploads={@uploads} />
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
    <div class="is-size-5 mx-large" style="margin-top: 200px;">
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
    <div class="mx-large has-font-3 is-size-5" style="margin-top: 200px;">
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
                class="has-font-3 is-size-5"
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
    <div class="mx-large has-font-3 is-size-5">
      <div style="display: inline-block; position: relative; left: 100px;">
        <ProductComponent.product product={product_type(@product_type)} />
      </div>
      <div style="display: inline-block; position: relative; left: 135px; top: 175px;">
        <div style="display: inline-block; text-align: right;">
          <div style="margin-bottom: 35px;">
            logo (opcional)
          </div>
          <div style="margin-bottom: 25px;">
            nome do produto
          </div>
          <div style="margin-bottom: 100px;">
            descrição breve
          </div>
          <div style="margin-bottom: 0px;">
            descrição completa
          </div>
        </div>
        <div style="display: inline-block; position: relative; top: 60px; left: 5px;">
          <div style="margin-bottom: 35px;">
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
          <div style="margin-bottom: 25px;">
            <form phx-change="product-name-change">
              <textarea
                type="text"
                name="product-name"
                class="has-font-3"
                style="width: 300px; height: 45px; border: 1px solid gray; text-align: center; font-size: 22px; overflow: hidden; resize: none;"
              />
            </form>
          </div>
          <div style="margin-bottom: 50px;">
            <form phx-change="descr-short-change">
              <textarea
                type="text"
                name="descr-short"
                wrap="soft"
                class="has-font-3"
                maxlength="100"
                style="width: 300px; height: 90px; border: 1px solid gray; text-align: center; font-size: 22px; overflow: scroll; overflow-x: hidden; resize: none;"
              />
            </form>
          </div>
          <div style="margin-bottom: 0px;">
            <form phx-change="descr-long-change">
              <textarea
                type="text"
                name="descr-long"
                wrap="soft"
                class="has-font-3"
                maxlength="350"
                style="width: 300px; height: 90px; border: 1px solid gray; text-align: center; font-size: 22px; overflow: scroll; overflow-x: hidden; resize: none;"
              />
            </form>
          </div>
        </div>
      </div>
      <div style="display: inline-block; position: relative; left: 250px; top: 250px;">
        <.next_button phx-value-step="submit" />
      </div>
    </div>
    """
  end

  slot :center, required: true

  defp body(assigns) do
    ~H"""
    <div class="columns">
      <div class="column is-3"></div>
      <div class="column has-font-3 is-size-5">
        <%= render_slot(@center) %>
      </div>
    </div>
    """
  end

  attr :uploads, :any, required: true

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
      <form id="design-upload-form" phx-submit="design-upload-save" phx-change="design-upload-change">
        <.live_file_input upload={@uploads.design} />
        <button type="submit">Upload</button>
      </form>

      <%!-- use phx-drop-target with the upload ref to enable file drag and drop --%>
      <section phx-drop-target={@uploads.design.ref}>
        <%!-- render each design entry --%>
        <%= for entry <- @uploads.design.entries do %>
          <article class="upload-entry">
            <figure>
              <.live_img_preview entry={entry} style="width: 100px;" />
              <figcaption><%= entry.client_name %></figcaption>
            </figure>

            <%!-- entry.progress will update automatically for in-flight entries --%>
            <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>

            <%!-- a regular click event whose handler will invoke Phoenix.LiveView.cancel_upload/3 --%>
            <button
              type="button"
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              aria-label="cancel"
            >
              &times;
            </button>

            <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
            <%= for err <- upload_errors(@uploads.design, entry) do %>
              <p class="alert alert-danger"><%= error_to_string(err) %></p>
            <% end %>
          </article>
        <% end %>

        <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
        <%= for err <- upload_errors(@uploads.design) do %>
          <p class="alert alert-danger"><%= error_to_string(err) %></p>
        <% end %>
      </section>
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
      <div class="column is-6 has-font-3 is-size-5" style="display: flex; justify-content: center;">
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
