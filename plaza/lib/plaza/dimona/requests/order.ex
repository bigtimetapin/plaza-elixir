defmodule Plaza.Dimona.Requests.Order do
  alias Plaza.Products
  alias Plaza.Purchases

  @sku_map %{
    "white-p" => "010101110108",
    "white-m" => "010101110109",
    "white-g" => "010101110110",
    "white-gg" => "010101110111",
    "white-xgg" => "010101110112"
  }

  def post(data) do
    Plaza.Dimona.Api.post("/api/v3/order", data)
  end

  def build(purchase) do
    ## map product ids to query full product info
    product_ids = purchase.products |> Enum.map(fn item -> item["product_id"] end)
    products = Products.all_in_list(product_ids)
    ## sort purchase info for join 
    purchase_info = purchase.products |> Enum.sort_by(fn item -> item["product_id"] end)
    ## sort product info for join 
    product_info = products |> Enum.sort_by(fn item -> item.id end)
    ## join
    case Enum.count(purchase_info) == Enum.count(product_info) do
      true ->
        items = Enum.zip(purchase_info, product_info)

        items =
          items
          |> Enum.map(fn
            {purchase, product} ->
              %{
                name: "Classic #{String.upcase(purchase["size"])} Branca",
                sku: product.id,
                dimona_sku_id: Map.get(@sku_map, "white-#{purchase["size"]}"),
                qty: purchase["quantity"],
                designs:
                  [
                    product.designs.front,
                    product.designs.back
                  ]
                  |> Enum.filter(& &1),
                mocks: [
                  product.mocks.front,
                  product.mocks
                ]
              }
          end)

        body = %{
          order_id: purchase.id,
          delivery_method_id: purchase.shipping_method_id,
          customer_name: purchase.customer_name,
          customer_email: purchase.email,
          items: items,
          address: %{
            name: purchase.customer_name,
            street: purchase.shipping_address_line1,
            complement: purchase.shipping_address_line2,
            zipcode: purchase.shipping_address_postal_code,
            country: "BR"
          }
        }

        {:ok, body}

      false ->
        :error
    end
  end
end
