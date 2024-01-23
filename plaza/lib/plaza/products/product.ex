defmodule Plaza.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  alias Plaza.Products.EctoDesigns
  alias Plaza.Products.EctoMocks

  schema "products" do
    field :user_id, :id
    field :user_name, :string
    field :name, :string
    field :price, :float
    field :internal_expense, :float
    field :description, :string
    field :designs, EctoDesigns
    field :mocks, EctoMocks
    field :campaign_duration, :integer
    field :campaign_duration_timestamp, :naive_datetime
    field :active, :boolean
    field :curated, :boolean
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
      :user_name,
      :name,
      :price,
      :internal_expense,
      :description,
      :designs,
      :mocks,
      :campaign_duration,
      :campaign_duration_timestamp,
      :active,
      :curated
    ])
    |> validate_required([
      :user_id,
      :user_name,
      :name,
      :price,
      :internal_expense,
      :description,
      :designs,
      :mocks,
      :campaign_duration,
      :campaign_duration_timestamp,
      :active,
      :curated
    ])
    |> unique_constraint([
      :user_id,
      :name
    ])
    |> validate_length(:description, max: 140)
    |> validate_number(:price, greater_than_or_equal_to: 50)
  end

  def changeset_internal_expense(product, attrs) do
    product
    |> cast(attrs, [
      :internal_expense
    ])
    |> validate_required([
      :internal_expense
    ])
  end

  def changeset_price(product, attrs, internal_expense) do
    product
    |> cast(attrs, [
      :price
    ])
    |> validate_required([
      :price
    ])
    |> validate_number(:price, greater_than_or_equal_to: internal_expense)
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

  def changeset_designs_and_mocks(product, attrs) do
    product
    |> cast(attrs, [
      :designs,
      :mocks
    ])
    |> validate_required([
      :designs,
      :mocks
    ])
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
