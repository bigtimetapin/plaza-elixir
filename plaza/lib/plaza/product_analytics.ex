defmodule Plaza.ProductAnalytics do
  import Ecto.Query, warn: false
  alias Plaza.Repo

  alias Plaza.Products.ProductAnalytics

  def increment_total_purchased(product_id, inc) do
    Repo.insert(
      %ProductAnalytics{
        product_id: product_id,
        total_purchased: inc
      },
      conflict_target: :product_id,
      on_conflict: [
        inc: [
          total_purchased: inc
        ]
      ]
    )
  end
end
