defmodule Plaza.Repo.Migrations.DropProductsTable02 do
  use Ecto.Migration

  def change do
    drop table("products")
  end
end
