defmodule PlazaWeb.UploadLive3 do
  use PlazaWeb, :live_view

  @aws_s3_region "us-west-2"
  @aws_s3_bucket "plaza-static-dev"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(step: 1)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("new-png-selected", file_name, socket) do
    IO.inspect(file_name)

    socket =
      socket
      |> assign(file_name: file_name)

    {:noreply, socket}
  end

  def handle_event("next", _, socket) do
    socket =
      socket
      |> assign(step: 2)

    {:noreply, socket}
  end

  def handle_event("back", _, socket) do
    socket =
      socket
      |> assign(step: 1)

    {:noreply, socket}
  end

  def handle_event("upload", _, socket) do
    config = %{
      region: @aws_s3_region,
      access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID_PLAZA"),
      secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY_PLAZA")
    }

    {:ok, fields} =
      PlazaWeb.S3UrlPresign.sign_form_upload(
        config,
        @aws_s3_bucket,
        key: socket.assigns.file_name,
        content_type: "image/png",
        max_file_size: 10_000_000,
        expires_in: :timer.hours(1)
      )

    IO.inspect(fields["policy"])
    fields = Map.put(fields, "policy", String.reverse(fields["policy"]))
    IO.inspect(fields["policy"])
    url = "http://#{@aws_s3_bucket}.s3-#{@aws_s3_region}.amazonaws.com"

    socket =
      socket
      |> push_event("upload", %{url: url, fields: fields})

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(%{step: 1} = assigns) do
    ~H"""
    <div style="display: flex; justify-content: center; font-size: 24px;" class="has-font-3">
      <script id="upload-3-file-reader" phx-hook="FileReader" />
      <form>
        <input type="file" id="upload-3-file-input" accept=".png" multiple={false} />
      </form>
      <img id="upload-3-file-display" src="png/pep.png" style="width: 300px;" />
      <img id="upload-3-file-display-2" src="png/pep.png" style="width: 500px;" />
    </div>
    <button phx-click="next">
      next
    </button>
    """
  end

  def render(%{step: 2} = assigns) do
    ~H"""
    <div id="upload-3-file-uploader" phx-hook="S3FileUploader">
      <button phx-click="back">
        back
      </button>
      <button phx-click="upload">
        upload
      </button>
    </div>
    """
  end
end
