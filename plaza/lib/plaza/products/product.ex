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
    |> validate_number(:price, greater_than_or_equal_to: 50)
  end

  def changeset_price(product, attrs) do
    product
    |> cast(attrs, [
      :price
    ])
    |> validate_required([
      :price
    ])
    |> validate_number(:price, greater_than_or_equal_to: 50)
  end

  def changeset_name_and_description(product, attrs) do
    product
    |> cast(attrs, [
      :name,
      :description
    ])
    |> validate_required([
      :name,
      :description
    ])
    |> validate_length(:description, max: 140)
  end
end
