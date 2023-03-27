defmodule Plaza.Repo.Migrations.DropProductsTable do
  use Ecto.Migration

  def change do
    drop table("products")

  end
end
