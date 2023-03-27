defmodule Plaza.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :alto, :boolean, default: false
    field :name, :string
    field :price, :string

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :price, :alto])
    |> validate_required([:name, :price, :alto])
  end
end
