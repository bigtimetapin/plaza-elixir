defmodule Plaza.Repo.Migrations.AddMailingListTable do
  use Ecto.Migration

  def change do
    create table(:mailing_list) do
      add :email, :string, null: false
      timestamps()
    end

    create unique_index(:mailing_list, [:email])
  end
end
