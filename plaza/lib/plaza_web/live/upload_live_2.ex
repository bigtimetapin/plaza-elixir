defmodule PlazaWeb.UploadLive2 do
  use PlazaWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Upload")
      |> assign(:header, :upload)
      |> allow_upload(:front, accept: ~w(.png), max_entries: 1)
      |> allow_upload(:back, accept: ~w(.png), max_entries: 1)
      |> assign(:step, 1)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("step", %{"step" => "2"}, socket) do
    socket =
      socket
      |> assign(:step, 2)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "3"}, socket) do
    IO.inspect(socket)

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

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "6"}, socket) do
    socket =
      socket
      |> assign(:step, 6)

    {:noreply, socket}
  end

  def handle_event("step", %{"step" => "7"}, socket) do
    socket =
      socket
      |> assign(:step, 7)

    {:noreply, socket}
  end

  def handle_event("front-upload-change", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("front-upload-cancel", %{"ref" => ref}, socket) do
    {:noreply, Phoenix.LiveView.cancel_upload(socket, :front, ref)}
  end

  def handle_event("back-upload-change", _params, socket) do
    {:noreply, socket}
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
    <PlazaWeb.UploadLive2.header step={@step} />
    <.upload_form current={@uploads.front} front={@uploads.front} back={@uploads.back} />
    <button phx-click="step" phx-value-step="4">
      next
    </button>
    """
  end

  def render(%{step: 4} = assigns) do
    ~H"""
    <PlazaWeb.UploadLive2.header step={@step} />
    <.upload_form current={@uploads.back} front={@uploads.front} back={@uploads.back} />
    """
  end

  def render(%{step: 5} = assigns) do
    ~H"""
    <PlazaWeb.UploadLive2.header step={@step} />
    """
  end

  def render(%{step: 6} = assigns) do
    ~H"""
    <PlazaWeb.UploadLive2.header step={@step} />
    """
  end

  def render(%{step: 7} = assigns) do
    ~H"""
    <PlazaWeb.UploadLive2.header step={@step} />
    """
  end

  attr :step, :integer, required: true

  def header(assigns) do
    ~H"""
    <div style="display: flex; justify-content: center;">
      <nav class="has-font-3 is-size-5">
        <a
          phx-click="step"
          phx-value-step="3"
          class="has-black-text mr-small"
          style="display: inline-block;"
        >
          Configurar Estampa
          <img
            :if={Enum.member?([3, 4, 5], @step)}
            src="svg/yellow-circle.svg"
            style="position: relative; left: 87px;"
          />
        </a>
        <img src="svg/seperator.svg" class="mr-small" style="display: inline-block;" />
        <a
          phx-click="step"
          phx-value-step="6"
          class="has-black-text mr-small"
          style="display: inline-block;"
        >
          Configuração de Campanha
          <img :if={@step == 6} src="svg/yellow-circle.svg" style="position: relative; left: 123px;" />
        </a>
        <img src="svg/seperator.svg" class="mr-small" style="display: inline-block;" />
        <a phx-click="step" phx-value-step="7" class="has-black-text" style="display: inline-block;">
          Publique seu Produto
          <img :if={@step == 7} src="svg/yellow-circle.svg" style="position: relative; left: 93px;" />
        </a>
      </nav>
    </div>
    """
  end

  attr :current, Phoenix.LiveView.UploadConfig, required: true
  attr :front, Phoenix.LiveView.UploadConfig, required: true
  attr :back, Phoenix.LiveView.UploadConfig, required: true

  defp upload_form(assigns) do
    ~H"""
    <div style="margin-top: 50px; margin-left: 25px;">
      <.upload_input upload={@current} />
      <.upload_item upload={@front} no_file_yet="front.png not uploaded yet" />
      <.upload_item upload={@back} no_file_yet="back.png not uploaded yet" />
    </div>
    """
  end

  attr :upload, Phoenix.LiveView.UploadConfig, required: true

  defp upload_input(assigns) do
    ~H"""
    <div style="display: inline-block;">
      <form id="front-upload-form" phx-submit="front-upload-save" phx-change="front-upload-change">
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
  attr :no_file_yet, :string, required: true

  defp upload_item(assigns) do
    map =
      case assigns.upload.entries do
        [head | []] ->
          head

        _ ->
          %{client_name: assigns.no_file_yet, client_size: 0}
      end

    IO.inspect(map)

    assigns =
      assigns
      |> assign(upload_item: map)

    ~H"""
    <div>
      <div class="has-font-3 is-size-6">
        <%= @upload_item.client_name %>
        <button
          :if={@upload_item.client_size > 0}
          type="button"
          phx-click={"#{@upload_item.upload_config}-upload-cancel"}
          phx-value-ref={@upload_item.ref}
          aria-label="cancel"
        >
          &times;
        </button>
      </div>
    </div>
    """
  end
end
