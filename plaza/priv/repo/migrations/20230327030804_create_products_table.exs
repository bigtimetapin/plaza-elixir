defmodule Plaza.Repo.Migrations.CreateProductsTable do
  use Ecto.Migration

  def change do
    create table("products") do
      add :name, :string
      add :price, :money
      add :alto, :boolean

      timestamps()
    end
  end
end
