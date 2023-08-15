defmodule Plaza.Dimona.Requests.Order do
  def post(data) do
    Plaza.Dimona.Api.post("/api/v3/order", data)
  end
end
