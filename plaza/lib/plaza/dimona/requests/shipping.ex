defmodule Plaza.Dimona.Requests.Shipping do
  def post(data) do
    Plaza.Dimona.Api.post("/api/v2/shipping", data)
  end
end
