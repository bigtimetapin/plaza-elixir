defmodule Plaza.Repo.Migrations.AddPurchasesTable do
  use Ecto.Migration

  def change do
    create table(:purchases) do
      add :user_id, references(:users, on_delete: :delete_all), null: true
      add :products, {:array, :map}, null: false
      add :sellers, {:array, :map}, null: false
      add :sellers_paid, :boolean, null: false
      add :email, :string, null: false
      add :stripe_session_id, :string, null: false
      add :shipping_method_id, :string, null: false
      add :shipping_method_price, :integer, null: false
      add :shipping_address_line1, :string, null: false
      add :shipping_address_line2, :string, null: true
      add :shipping_address_city, :string, null: true
      add :shipping_address_state, :string, null: true
      add :shipping_address_postal_code, :string, null: false
      add :shipping_address_country, :string, null: true
      timestamps()
    end

    create index(:purchases, [:email])
  end
end
