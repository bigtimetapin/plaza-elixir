defmodule Plaza.Repo.Migrations.AddProductsTable do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :front_url, :string
      timestamps()
    end

    create index(:products, [:user_id])
    create unique_index(:products, [:user_id, :name])
  end
end
