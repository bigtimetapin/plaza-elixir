defmodule Plaza.Repo.Migrations.AddPurchasesTable do
  use Ecto.Migration

  def change do
    create table(:purchases) do
      add :user_id, references(:users, on_delete: :delete_all), null: true
      add :product_id, references(:products), null: true
      add :email, :string, null: false
      add :status, :string, null: false
    end

    create index(:purchases, [:email])
  end
end
