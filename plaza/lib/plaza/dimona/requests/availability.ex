defmodule Plaza.Dimona.Requests.Availability do
  def get(sku) do
    Plaza.Dimona.Api.get("/api/v2/sku/#{sku}/availability")
  end
end
