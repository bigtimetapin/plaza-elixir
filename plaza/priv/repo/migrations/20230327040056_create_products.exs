defmodule Plaza.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :price, :string
      add :alto, :boolean, default: false, null: false

      timestamps()
    end
  end
end
