defmodule Plaza.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :descr_long, :string
    field :descr_short, :string
    field :name, :string
    field :num_colors, :integer
    field :num_expected, :integer
    field :product_type, :integer
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :descr_short, :descr_long, :product_type, :num_colors, :num_expected])
    |> validate_required([:name, :descr_short, :descr_long, :product_type, :num_colors, :num_expected])
  end
end
