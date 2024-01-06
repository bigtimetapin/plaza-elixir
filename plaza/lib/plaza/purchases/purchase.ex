defmodule Plaza.Purchases.Purchase do
  use Ecto.Schema
  import Ecto.Changeset

  schema "purchases" do
    field :user_id, :id
    field :products, {:array, :map}
    field :sellers, {:array, :map}
    field :sellers_paid, :boolean
    field :email, :string
    field :stripe_session_id, :string
    field :shipping_method_id, :string
    field :shipping_method_price, :integer
    field :shipping_address_line1, :string
    field :shipping_address_line2, :string
    field :shipping_address_city, :string
    field :shipping_address_state, :string
    field :shipping_address_postal_code, :string
    field :shipping_address_country, :string
    timestamps()
  end

  def changeset(purchase, attrs) do
    purchase
    |> cast(attrs, [
      :user_id,
      :products,
      :sellers,
      :sellers_paid,
      :email,
      :stripe_session_id,
      :shipping_method_id,
      :shipping_method_price,
      :shipping_address_line1,
      :shipping_address_line2,
      :shipping_address_city,
      :shipping_address_state,
      :shipping_address_postal_code,
      :shipping_address_country
    ])
    |> validate_required([
      :products,
      :sellers,
      :sellers_paid,
      :email,
      :stripe_session_id,
      :shipping_method_id,
      :shipping_method_price,
      :shipping_address_line1,
      :shipping_address_postal_code
    ])
  end
end
