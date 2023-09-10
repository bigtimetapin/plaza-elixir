defmodule Plaza.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  alias Plaza.Products.EctoDesigns
  alias Plaza.Products.EctoMocks

  schema "products" do
    field :user_id, :id
    field :name, :string
    field :price, :float
    field :campaign_duration, :integer
    field :description, :string
    field :designs, EctoDesigns
    field :mocks, EctoMocks
    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [
      :user_id,
      :name,
      :price,
      :campaign_duration,
      :description,
      :designs,
      :mocks
    ])
    |> validate_required([
      :user_id,
      :name,
      :price,
      :campaign_duration,
      :description,
      :designs,
      :mocks
    ])
    |> unique_constraint([
      :user_id,
      :name
    ])
    |> validate_length(:description, max: 140)
  end
end
