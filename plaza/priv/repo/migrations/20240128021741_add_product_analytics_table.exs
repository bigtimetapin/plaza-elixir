defmodule Plaza.Repo.Migrations.AddProductAnalyticsTable do
  use Ecto.Migration

  def change do
    create table(:product_analytics) do
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :total_purchased, :integer, null: false
      timestamps()
    end

    create unique_index(:product_analytics, [:product_id])
  end
end
