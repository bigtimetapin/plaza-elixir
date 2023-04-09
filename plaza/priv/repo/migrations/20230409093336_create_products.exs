defmodule Plaza.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :descr_short, :string
      add :descr_long, :text
      add :product_type, :integer
      add :num_colors, :integer
      add :num_expected, :integer
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:products, [:user_id])
  end
end
