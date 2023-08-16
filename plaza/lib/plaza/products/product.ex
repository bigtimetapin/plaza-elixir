defmodule Plaza.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :user_id, :id
    field :name, :string
    field :front_url, :string
    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [
      :user_id,
      :name,
      :front_url
    ])
    |> validate_required([
      :user_id,
      :name
    ])
    |> unique_constraint([
      :user_id,
      :name
    ])
  end
end
