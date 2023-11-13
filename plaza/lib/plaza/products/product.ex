defmodule Plaza.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  alias Plaza.Products.EctoDesigns
  alias Plaza.Products.EctoMocks

  schema "products" do
    field :user_id, :id
    field :name, :string
    field :price, :float
    field :description, :string
    field :designs, EctoDesigns
    field :mocks, EctoMocks
    field :campaign_duration, :integer
    field :campaign_duration_timestamp, :naive_datetime
    field :active, :boolean
    timestamps()
  end

  def price_unit_amount(product) do
    Kernel.round(product.price * 100)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [
      :user_id,
      :name,
      :price,
      :description,
      :designs,
      :mocks,
      :campaign_duration,
      :campaign_duration_timestamp,
      :active
    ])
    |> validate_required([
      :user_id,
      :name,
      :price,
      :description,
      :designs,
      :mocks,
      :campaign_duration,
      :campaign_duration_timestamp,
      :active
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

  def changeset_designs(product, attrs) do
    product
    |> cast(attrs, [
      :designs
    ])
    |> validate_required(:designs)
  end

  def changeset_campaign_duration(product, attrs) do
    product
    |> cast(attrs, [
      :campaign_duration,
      :campaign_duration_timestamp
    ])
    |> validate_required([
      :campaign_duration,
      :campaign_duration_timestamp
    ])
  end
end
