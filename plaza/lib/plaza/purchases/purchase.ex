defmodule Plaza.Purchases.Purchase do
  use Ecto.Schema
  import Ecto.Changeset

  schema "purchases" do
    field :user_id, :id
    field :product_id, :id
    field :email, :string
    field :status, :string
    timestamps()
  end

  def changeset(purchase, attrs) do
    purchase
    |> cast(attrs, [
      :user_id,
      :product_id,
      :email,
      :status
    ])
    |> validate_required([
      :product_id,
      :email,
      :status
    ])
  end
end
