defmodule Plaza.Dimona.Api do
  @base_url "https://camisadimona.com.br"

  def post(url, data) do
    {:ok, data} = Poison.encode(data)

    case HTTPoison.post(@base_url <> url, data, headers()) do
      {:ok, %{status_code: 404}} ->
        {:error, :not_found}

      {:ok, %{status_code: 401}} ->
        {:error, :unauthorised}

      {:ok, %{status_code: 400}} ->
        {:error, :bad_request}

      {:ok, %{status_code: 204}} ->
        {:ok, nil}

      {:ok, %{body: body, status_code: 201}} ->
        {:ok, Poison.decode!(body, keys: :atoms)}

      {:ok, %{body: body, status_code: 200}} ->
        {:ok, Poison.decode!(body, keys: :atoms)}

      {:ok, %{body: body}} = resp ->
        {:error, body}

      _ ->
        {:error, :bad_network}
    end
  end

  def get(url) do
    case HTTPoison.get(@base_url <> url, headers()) do
      {:ok, %{status_code: 404}} ->
        {:error, :not_found}

      {:ok, %{status_code: 401}} ->
        {:error, :unauthorised}

      {:ok, %{status_code: 400}} ->
        {:error, :bad_request}

      {:ok, %{status_code: 204}} ->
        {:ok, nil}

      {:ok, %{body: body, status_code: 201}} ->
        {:ok, Poison.decode!(body, keys: :atoms)}

      {:ok, %{body: body, status_code: 200}} ->
        {:ok, Poison.decode!(body, keys: :atoms)}

      {:ok, %{body: body}} = resp ->
        {:error, body}

      _ ->
        {:error, :bad_network}
    end
  end

  defp headers() do
    [
      {"api-key", Plaza.Dimona.Config.get()},
      {"Accept", "application/json"},
      {"Content-Type", "application/json"}
    ]
  end
end
