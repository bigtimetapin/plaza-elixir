defmodule Plaza.Accounts.Address do
  use Ecto.Schema
  import Ecto.Changeset

  schema "addresses" do
    field :user_id, :id
    field :line1, :string
    field :line2, :string
    field :line3, :string
    field :city, :string
    field :state, :string
    field :postal_code, :string
    field :country, :string
    timestamps()
  end

  def changeset(address, attrs) do
    address
    |> cast(attrs, [
      :user_id,
      :line1,
      :line2,
      :line3,
      :city,
      :state,
      :postal_code,
      :country
    ])
    |> validate_required([
      :line1,
      :line2,
      :postal_code,
      :city,
      :state
    ])
    |> validate_length(:postal_code, is: 9)
    |> validate_length(:country, min: 2, max: 2)
  end

  def changeset_no_postal_code(address, attrs) do
    address
    |> cast(attrs, [
      :user_id,
      :line1,
      :line2,
      :line3,
      :city,
      :state,
      :country
    ])
    |> validate_length(:country, min: 2, max: 2)
  end

  def changeset_postal_code(address, attrs) do
    address
    |> cast(attrs, [
      :postal_code
    ])
    |> validate_required([
      :postal_code
    ])
    |> validate_length(:postal_code, is: 9)
  end
end
