defmodule Plaza.Repo.Migrations.AddTopColumn do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :top, :boolean, default: false
    end
  end
end
