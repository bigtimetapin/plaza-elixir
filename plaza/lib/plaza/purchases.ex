defmodule Plaza.Purchases do
  import Ecto.Query, warn: false

  alias Plaza.Repo
  alias Plaza.Purchases.Purchase

  def get!(id), do: Repo.get!(Purchase, id)

  def create(attrs) do
    %Purchase{}
    |> Purchase.changeset(attrs)
    |> Repo.insert()
  end

  def update(%Purchase{} = purchase, attrs) do
    purchase
    |> Purchase.changeset(attrs)
    |> Repo.update()
  end
end
