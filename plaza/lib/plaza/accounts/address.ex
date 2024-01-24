defmodule Plaza.Accounts.Address do
  use Ecto.Schema
  import Ecto.Changeset

  schema "addresses" do
    field :user_id, :id
    field :line1, :string
    field :line2, :string
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
      :city,
      :state,
      :postal_code,
      :country
    ])
    |> validate_required([
      :line1,
      :postal_code
    ])
    |> validate_length(:postal_code, is: 9)
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

  def to_dimona_form(address) do
    %{
      "street" => address.line1,
      "complement" => address.line2,
      "city" => address.city,
      "state" => address.state,
      "zipcode" => address.postal_code
    }
  end
end
