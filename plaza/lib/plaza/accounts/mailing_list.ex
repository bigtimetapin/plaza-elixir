defmodule Plaza.Accounts.MailingList do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mailing_list" do
    field :email, :string
    timestamps()
  end

  def changeset(mailing_list, email) do
    mailing_list
    |> cast(
      %{"email" => email},
      [:email]
    )
    |> validate_required([
      :email
    ])
  end
end
