defmodule Plaza.Repo.Migrations.AddProductsTable do
  use Ecto.Migration

  # TODO; activity, stats
  def change do
    create table(:products) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :price, :float, null: false
      add :campaign_duration, :integer, null: false
      add :description, :string, size: 140, null: false
      add :designs, :map, null: false
      add :mocks, :map, null: false
      timestamps()
    end

    create unique_index(:products, [:user_id, :name])
  end
end
