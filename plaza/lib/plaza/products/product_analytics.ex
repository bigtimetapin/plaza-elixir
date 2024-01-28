defmodule Plaza.Products.ProductAnalytics do
  use Ecto.Schema
  import Ecto.Changeset

  schema "product_analytics" do
    field :product_id, :id
    field :total_purchased, :integer
    timestamps()
  end

  def changeset(product_analytics, attrs) do
    product_analytics
    |> cast(attrs, [
      :product_id,
      :total_purchased
    ])
    |> validate_required([
      :product_id,
      :total_purchased
    ])
  end
end
