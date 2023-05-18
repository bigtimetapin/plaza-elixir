defmodule Plaza.Repo.Migrations.AddDesignUrlColumn do
  use Ecto.Migration

  def change do
    alter table("products") do
      add :design_url, :string
    end
  end
end
