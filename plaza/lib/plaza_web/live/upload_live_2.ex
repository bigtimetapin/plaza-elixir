defmodule PlazaWeb.UploadLive2 do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias Plaza.Accounts.Seller
  alias Plaza.Products

  alias ExAws
  alias ExAws.S3

  @site "https://plazaaaaa.fly.dev"

  @aws_s3_region "us-west-2"
  @aws_s3_bucket "plaza-static-dev"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {seller, step} =
      case socket.assigns.current_user do
        nil ->
          {nil, 1}

        %{id: id} ->
          case Accounts.get_seller_by_id(id) do
            nil ->
              {nil, 4}

            %Seller{stripe_id: nil} = seller ->
              {seller, 5}

            seller ->
              {seller, 6}
          end
      end

    socket =
      socket
      |> assign(:page_title, "Upload")
      |> assign(:header, :my_store)
      |> allow_upload(:front,
        accept: ~w(.png),
        max_entries: 1,
        auto_upload: true,
        progress: &handle_progress/3
      )
      |> allow_upload(:back,
        accept: ~w(.png),
        max_entries: 1,
        auto_upload: true,
        progress: &handle_progress/3
      )
      |> assign(:front_local_upload, nil)
      |> assign(:back_local_upload, nil)
      |> assign(:seller, seller)
      |> assign(:step, step)

    {:ok, socket}
  end

  defp handle_progress(:front, entry, socket) do
    handle_progress_generic(:front_local_upload, entry, socket)
  end

  defp handle_progress(:back, entry, socket) do
    handle_progress_generic(:back_local_upload, entry, socket)
  end

  defp handle_progress_generic(local_upload_atom, entry, socket) do
    socket =
      if entry.done? do
        {local_url, file_name} =
          consume_uploaded_entry(socket, entry, fn %{path: path} ->
            IO.inspect(path)
            unique_file_name = "#{entry.uuid}-#{entry.client_name}"

            dest =
              Path.join([
                :code.priv_dir(:plaza),
                "static",
                "uploads",
                unique_file_name
              ])

            File.cp!(path, dest)
            {:ok, {"uploads/#{unique_file_name}", entry.client_name}}
          end)

        IO.inspect(local_url)

        socket =
          socket
          |> assign(local_upload_atom, %{url: local_url, file_name: file_name})
      else
        socket
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("step", %{"step" => "noop"}, socket) do
    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "2"}, socket) do
    socket =
      socket
      |> assign(:step, 2)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "3"}, socket) do
    socket =
      socket
      |> assign(:step, 3)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "4"}, socket) do
    socket =
      socket
      |> assign(:step, 4)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "5"}, socket) do
    socket =
      socket
      |> assign(:step, 5)

    IO.inspect(socket.assigns.uploads.front)

    IO.inspect(socket.assigns.uploads.back)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "6"}, socket) do
    socket =
      socket
      |> assign(:step, 6)

    IO.inspect(socket.assigns.uploads.front)

    IO.inspect(socket.assigns.uploads.back)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "7"}, socket) do
    socket =
      socket
      |> assign(:step, 7)

    IO.inspect(socket.assigns.uploads.front)

    IO.inspect(socket.assigns.uploads.back)

    {:noreply, socket}
  end

  def handle_event("upload-change", _params, socket) do
    IO.inspect(socket.assigns.uploads.front)

    IO.inspect(socket.assigns.uploads.back)
    {:noreply, socket}
  end

  def handle_event("upload-submit", params, socket) do
    IO.inspect(params)
    IO.inspect(socket.assigns.uploads.front)

    IO.inspect(socket.assigns.uploads.back)

    {:noreply, socket}
  end

  def handle_event("tmp-submit", _params, socket) do
    src =
      Path.join([
        :code.priv_dir(:plaza),
        "static",
        socket.assigns.front_local_upload.url
      ])

    request =
      S3.put_object(
        @aws_s3_bucket,
        socket.assigns.front_local_upload.url,
        File.read!(src)
      )

    response =
      ExAws.request!(
        request,
        region: @aws_s3_region
      )

    IO.inspect(response)

    url =
      "https://#{@aws_s3_bucket}.s3.us-west-2.amazonaws.com/#{socket.assigns.front_local_upload.url}"

    {:noreply, socket}
  end

  def handle_event("front-upload-cancel", _params, socket) do
    socket =
      socket
      |> assign(:front_local_upload, nil)

    {:noreply, socket}
  end

  def handle_event("back-upload-cancel", _params, socket) do
    socket =
      socket
      |> assign(:back_local_upload, nil)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(%{step: 1} = assigns) do
    ~H"""
    <div class="has-font-3 is-size-4" style="text-align: center; margin-top: 125px;">
      <div class="mb-xsmall">
        É Fácil e totalmente grátis.
      </div>
      <div class="mb-xsmall">
        Você faz o upload da sua arte, configura o produto, escolhe o preço de venda e publica sua campanha de vendas.
      </div>
      <div class="mb-xsmall">
        A partir daí você só precisa esperar pra receber seus lucros.
      </div>
      <div class="mb-xsmall">
        A gente vai produzir cada produto vendido e entregar direto na casa do cliente.
      </div>
      <div class="mb-xxsmall">
        <div>
          Fabricamos apenas o que for vendido, assim não temos desperdício de recursos.
        </div>
        <div style="position: relative; bottom: 15px;">
          Você recebe pelo que vender.
        </div>
      </div>
      <div class="mb-xsmall">
        E se não vender tudo bem, ninguém perde nada.
      </div>
    </div>
    <div style="display: flex; justify-content: center; margin-top: 85px; margin-bottom: 75px;">
      <button phx-click="step" phx-value-step="2">
        <img src="svg/yellow-ellipse.svg" />
        <div class="has-font-3 is-size-4" style="position: relative; bottom: 79px;">
          Criar Produto
        </div>
      </button>
    </div>
    """
  end

  def render(%{step: 2} = assigns) do
    ~H"""
    <div class="has-font-3 is-size-4" style="text-align: center; margin-top: 150px;">
      <div class="mb-xsmall">
        Tem mais um detalhe importante:
      </div>
      <div class="mb-xsmall">
        <div>
          Seu produto vai ficar disponível na nossa loja por tempo limitado.
        </div>
        <div style="position: relative; bottom: 15px;">
          Você pode decidir se sua campanha de vendas ficará disponível por 7, 14, 21 ou 30 dias.
        </div>
      </div>
      <div>
        <div>
          Após o final do prazo de vendas seu produto não estará mais disponível para encomendas.
        </div>
        <div style="position: relative; bottom: 15px;">
          Você tem liberdade de republicar o produto por mais períodos de até 30 dias novamente se quiser.
        </div>
      </div>
    </div>
    <div style="display: flex; justify-content: center; margin-top: 85px; margin-bottom: 50px;">
      <button phx-click="step" phx-value-step="3">
        <img src="svg/yellow-ellipse.svg" />
        <div class="has-font-3 is-size-4" style="position: relative; bottom: 79px;">
          Ok
        </div>
      </button>
    </div>
    """
  end

  def render(%{step: 3} = assigns) do
    ~H"""
    <div style="margin-top: 100px;">
      <div style="opacity: 50%; margin-bottom: 100px;">
        <PlazaWeb.UploadLive2.header step={@step} disabled={true} />
      </div>
      <div class="has-font-3 is-size-5 mx-large">
        <div>
          before your campaign goes live you'll need to register (login) and make a store (name, logo, etc)
          <div>
            you can register now or upload first and register later. which do you prefer?
          </div>
        </div>
        <div>
          <.link class="has-font-3" navigate="/users/register">
            register / login
          </.link>
        </div>
        <div>
          <button phx-click="step" phx-value-step="4">
            upload first
          </button>
        </div>
      </div>
    </div>
    """
  end

  def render(%{step: 4} = assigns) do
    ~H"""
    <div style="margin-top: 150px; margin-bottom: 750px;">
      <PlazaWeb.UploadLive2.header step={@step} />
      <div style="display: inline-block; position: absolute; margin-left: 50px;">
        <div style="margin-top: 50px;">
          <.upload_form
            current={@uploads.front}
            front={@uploads.front}
            back={@uploads.back}
            front_local_upload={@front_local_upload}
            back_local_upload={@back_local_upload}
          />
        </div>
      </div>
      <div style="display: inline-block; position: relative; left: 900px; top: 50px;">
        <div style="display: inline-block;">
          <%!-- flipping order in which elements are added to dom behaves as z-index --%>
          <.upload_preview local_url={@front_local_upload[:url]} />
        </div>
        <div style="display: inline-block; position: absolute;">
          <div style="position: relative; left: 25px;">
            <.upload_toggle step={@step} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(%{step: 5} = assigns) do
    ~H"""
    <div style="margin-top: 150px; margin-bottom: 750px;">
      <PlazaWeb.UploadLive2.header step={@step} />
      <div style="display: inline-block; position: absolute; margin-left: 50px;">
        <div style="margin-top: 50px;">
          <.upload_form
            current={@uploads.back}
            front={@uploads.front}
            back={@uploads.back}
            front_local_upload={@front_local_upload}
            back_local_upload={@back_local_upload}
          />
        </div>
      </div>
      <div style="display: inline-block; position: relative; left: 900px; top: 50px;">
        <div style="display: inline-block;">
          <%!-- flipping order in which elements are added to dom behaves as z-index --%>
          <.upload_preview local_url={@back_local_upload[:url]} />
        </div>
        <div style="display: inline-block; position: absolute;">
          <div style="position: relative; left: 25px;">
            <.upload_toggle step={@step} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(%{step: 6} = assigns) do
    ~H"""
    <div style="margin-top: 150px; margin-bottom: 750px;">
      <PlazaWeb.UploadLive2.header step={@step} />
      <div style="margin-top: 50px;">
        <div>
          <.upload_preview local_url={@front_local_upload[:url]} />
        </div>
        <div style="position: relative; left: 500px;">
          <.upload_preview local_url={@back_local_upload[:url]} />
        </div>
      </div>
      <div style="position: relative; left: 1500px;">
        <button phx-click="tmp-submit">
          submit
        </button>
      </div>
    </div>
    """
  end

  def render(%{step: 7} = assigns) do
    ~H"""
    <PlazaWeb.UploadLive2.header step={@step} />
    """
  end

  attr :step, :integer, required: true
  attr :disabled, :boolean, default: false

  def header(assigns) do
    ~H"""
    <div style="display: flex; justify-content: center;">
      <nav class="has-font-3 is-size-5">
        <a
          phx-click="step"
          phx-value-step={if @disabled, do: "noop", else: "4"}
          class="has-black-text mr-small"
          style="display: inline-block;"
        >
          Configurar Estampa
          <img
            :if={Enum.member?([3, 4, 5, 6], @step)}
            src="svg/yellow-circle.svg"
            style="position: relative; left: 87px;"
          />
        </a>
        <img src="svg/seperator.svg" class="mr-small" style="display: inline-block;" />
        <a
          phx-click="step"
          phx-value-step={if @disabled, do: "noop", else: "7"}
          class="has-black-text mr-small"
          style="display: inline-block;"
        >
          Configuração de Campanha
          <img :if={@step == 7} src="svg/yellow-circle.svg" style="position: relative; left: 123px;" />
        </a>
        <img src="svg/seperator.svg" class="mr-small" style="display: inline-block;" />
        <a
          phx-click="step"
          phx-value-step={if @disabled, do: "noop", else: "8"}
          class="has-black-text"
          style="display: inline-block;"
        >
          Publique seu Produto
          <img :if={@step == 8} src="svg/yellow-circle.svg" style="position: relative; left: 93px;" />
        </a>
      </nav>
    </div>
    """
  end

  attr :current, Phoenix.LiveView.UploadConfig, required: true
  attr :front, Phoenix.LiveView.UploadConfig, required: true
  attr :back, Phoenix.LiveView.UploadConfig, required: true
  attr :front_local_upload, :map, default: nil
  attr :back_local_upload, :map, default: nil

  defp upload_form(assigns) do
    ~H"""
    <div>
      <.upload_input upload={@current} />
      <div class="has-font-3" style="width: 760px; font-size: 28px;">
        <div style="margin-top: 25px;">
          Arquivo PNG com formato de cores RGB com pelo menos 300 dpi de resolução.
          Medidas ajustadas dentro dos limites do A3 (29 x 42 cm)
        </div>
        <div style="margin-top: 50px; margin-left: 20px;">
          Seus arquivos:
        </div>
      </div>
      <div style="margin-left: 20px;">
        <.upload_item
          upload={@front}
          local_file_name={@front_local_upload[:file_name]}
          no_file_yet="front.png"
        />
        <.upload_item
          upload={@back}
          local_file_name={@back_local_upload[:file_name]}
          no_file_yet="back.png"
        />
      </div>
    </div>
    """
  end

  attr :upload, Phoenix.LiveView.UploadConfig, required: true

  defp upload_input(assigns) do
    ~H"""
    <div>
      <form id="upload-form" phx-change="upload-change" phx-submit="upload-submit">
        <label
          class="has-font-3 is-size-4"
          style="width: 760px; height: 130px; border: 1px solid black; display: flex; justify-content: center; align-items: center;"
        >
          <.live_file_input upload={@upload} style="display: none;" />
          Arraste seus arquivos .png aqui para fazer upload
        </label>
      </form>
    </div>
    """
  end

  attr :upload, Phoenix.LiveView.UploadConfig, required: true
  attr :local_file_name, :string, default: nil
  attr :no_file_yet, :string, default: nil

  defp upload_item(assigns) do
    map =
      case assigns.upload.entries do
        [head | []] ->
          head

        _ ->
          case assigns.local_file_name do
            nil ->
              %{progress: 0}

            _ ->
              %{progress: 100}
          end
      end

    assigns =
      assigns
      |> assign(entry: map)

    ~H"""
    <div>
      <div class="has-font-3 is-size-6">
        <%= if @local_file_name, do: @local_file_name, else: @no_file_yet %>
        <div>
          <progress value={@entry.progress} max="100"><%= @entry.progress %>%</progress>
          <button
            :if={@local_file_name}
            type="button"
            phx-click={"#{@upload.name}-upload-cancel"}
            aria-label="cancel"
          >
            &times;
          </button>
        </div>
      </div>
    </div>
    """
  end

  attr :local_url, :string, default: nil

  defp upload_preview(assigns) do
    ~H"""
    <div>
      <img src="png/mockup-front.png" />
      <div style="overflow: hidden; width: 264px; height: 356px; position: relative; bottom: 560px; left: 205px; border: 1px dotted blue;">
        <img src={@local_url} />
      </div>
    </div>
    """
  end

  attr :step, :integer, required: true

  defp upload_toggle(assigns) do
    ~H"""
    <div>
      <div>
        <button
          :if={@step == 4}
          class="has-font-3 is-size-5"
          style="border-bottom: 2px solid black; height: 43px;"
        >
          Frente
        </button>
        <button
          :if={@step == 5}
          phx-click="step"
          phx-value-step="4"
          class="has-font-3 is-size-5"
          style="height: 43px;"
        >
          Frente
        </button>
      </div>
      <div>
        <button
          :if={@step == 4}
          phx-click="step"
          phx-value-step="5"
          type="submit"
          class="has-font-3 is-size-5"
          style="height: 43px;"
        >
          Costas
        </button>
        <button
          :if={@step == 5}
          class="has-font-3 is-size-5"
          style="border-bottom: 2px solid black; height: 43px;"
        >
          Costas
        </button>
      </div>
      <div style="position: relative; top: 620px; width: 200px;">
        <button :if={@step == 5} phx-click="step" phx-value-step="6">
          <img src="svg/yellow-ellipse.svg" />
          <div class="has-font-3 is-size-4" style="position: relative; bottom: 79px;">
            Próximo
          </div>
        </button>
      </div>
    </div>
    """
  end
end
