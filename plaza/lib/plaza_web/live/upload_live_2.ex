defmodule PlazaWeb.UploadLive2 do
  use PlazaWeb, :live_view

  alias Plaza.Accounts
  alias Plaza.Accounts.Seller
  alias Plaza.Products

  alias ExAws
  alias ExAws.S3

  ## TODO; overlay logo view on input 
  ## async task upload to s3: https://fly.io/phoenix-files/liveview-async-task/
  ## collect payout info after creating first product at /my-store

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
      |> allow_upload(:front, accept: ~w(.png), max_entries: 1, auto_upload: true)
      |> allow_upload(:back, accept: ~w(.png), max_entries: 1, auto_upload: true)
      |> assign(:seller, seller)
      |> assign(:step, step)

    {:ok, socket}
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

    IO.inspect(socket.assigns.uploads.front)

    IO.inspect(socket.assigns.uploads.back)

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

    {:noreply, socket}
  end

  def handle_event("upload-change", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("upload-submit", params, socket) do
    IO.inspect(params)
    IO.inspect(socket.assigns.uploads.front)

    IO.inspect(socket.assigns.uploads.back)

    {:noreply, socket}
  end

  def handle_event("tmp-submit", _params, socket) do
    [{file_name, src} | []] =
      consume_uploaded_entries(socket, :front, fn %{path: path}, entry ->
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

    request =
      S3.put_object(
        @aws_s3_bucket,
        file_name,
        File.read!(src)
      )

    response =
      ExAws.request!(
        request,
        region: @aws_s3_region
      )

    IO.inspect(response)

    url = "https://#{@aws_s3_bucket}.s3.us-west-2.amazonaws.com/#{file_name}"
    {:noreply, socket}
  end

  def handle_event("front-upload-cancel", %{"ref" => ref}, socket) do
    {:noreply, Phoenix.LiveView.cancel_upload(socket, :front, ref)}
  end

  def handle_event("back-upload-cancel", %{"ref" => ref}, socket) do
    {:noreply, Phoenix.LiveView.cancel_upload(socket, :back, ref)}
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
      <div style="margin-top: 50px;">
        <.upload_form
          current={@uploads.front}
          front={@uploads.front}
          back={@uploads.back}
          step={@step}
        />
        <%!-- flipping order in which elements are added to dom behaves as z-index --%>
        <.upload_preview upload={@uploads.back} />
        <.upload_preview upload={@uploads.front} />
      </div>
    </div>
    """
  end

  def render(%{step: 5} = assigns) do
    ~H"""
    <div style="margin-top: 150px; margin-bottom: 750px;">
      <PlazaWeb.UploadLive2.header step={@step} />
      <div style="margin-top: 50px;">
        <.upload_form
          current={@uploads.back}
          front={@uploads.front}
          back={@uploads.back}
          step={@step}
        />
        <.upload_preview upload={@uploads.front} step={@step} />
        <.upload_preview upload={@uploads.back} step={@step} />
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
          <.upload_preview upload={@uploads.front} step={@step} />
        </div>
        <div style="position: relative; left: 500px;">
          <.upload_preview upload={@uploads.back} step={@step} />
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

  attr :step, :integer, required: true

  defp upload_form(assigns) do
    ~H"""
    <div style="margin-left: 50px; display: inline-block;">
      <.upload_input upload={@current} step={@step} />
      <.upload_item upload={@front} no_file_yet="front.png not uploaded yet" />
      <.upload_item upload={@back} no_file_yet="back.png not uploaded yet" />
    </div>
    """
  end

  attr :upload, Phoenix.LiveView.UploadConfig, required: true
  attr :step, :integer, required: true

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

      <div style="position: relative;">
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
      </div>

      <div style="position: relative;">
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

  attr :upload, Phoenix.LiveView.UploadConfig, required: true
  attr :no_file_yet, :string, default: nil

  defp upload_item(assigns) do
    map =
      case assigns.upload.entries do
        [head | []] ->
          head

        _ ->
          %{client_name: assigns.no_file_yet, client_size: 0}
      end

    assigns =
      assigns
      |> assign(entry: map)

    ~H"""
    <div>
      <div class="has-font-3 is-size-6">
        <%= @entry.client_name %>
        <button
          :if={@entry.client_size > 0}
          type="button"
          phx-click={"#{@entry.upload_config}-upload-cancel"}
          phx-value-ref={@entry.ref}
          aria-label="cancel"
        >
          &times;
        </button>
      </div>
    </div>
    """
  end

  attr :upload, Phoenix.LiveView.UploadConfig, required: true

  defp upload_preview(assigns) do
    map =
      case assigns.upload.entries do
        [head | []] ->
          head

        _ ->
          %{client_size: 0}
      end

    assigns =
      assigns
      |> assign(entry: map)

    ~H"""
    <div style="display: inline-block; position: absolute">
      <div style="position: relative; left: 75px;">
        <img src="png/mockup-front.png" />
        <div style="overflow: hidden; width: 264px; height: 356px; position: relative; bottom: 560px; left: 205px; border: 1px dotted blue;">
          <.live_img_preview :if={@entry.client_size > 0} entry={@entry} />
        </div>
        <div style="position: relative; bottom: 1160px; left: 700px;"></div>
      </div>
    </div>
    """
  end
end
