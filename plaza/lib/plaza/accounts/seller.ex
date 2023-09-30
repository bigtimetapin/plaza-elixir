defmodule Plaza.Accounts.Seller do
  use Ecto.Schema
  alias Plaza.Accounts.EctoSocials

  schema "sellers" do
    field :user_id, :id
    field :user_name, :string
    field :profile_photo_url, :string
    field :description, :string
    field :location, :string
    field :website, :string
    field :socials, EctoSocials
    field :stripe_id, :string

    timestamps()
  end

  ## def changeset(seller, attrs) do
  ##   seller
  ##   |> cast(attrs, [
  ##     :user_id,
  ##     :user_name,
  ##     :profile_photo_url,
  ##     :description,
  ##     :location,
  ##     :website,
  ##     :stripe_id
  ##   ])
  ##   |> validate_required([
  ##     :user_id,
  ##     :user_name
  ##   ])
  ##   |> unique_constraint(:user_id)
  ##   |> unique_constraint(:user_name)
  ##   |> validate_length(:description, max: 140)
  ## end
end
