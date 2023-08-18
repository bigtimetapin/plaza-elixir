defmodule Plaza.Repo.Migrations.AddSellerTable do
  use Ecto.Migration

  def change do
    create table(:sellers) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :user_name, :string, null: false
      add :profile_photo_url, :string
      add :description, :string, size: 140
      add :location, :string
      add :website, :string
      add :socials, :map
      add :stripe_id, :string
      timestamps()
    end

    create unique_index(:sellers, [:user_name])
  end
end
