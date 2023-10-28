defmodule Plaza.Purchases do
  import Ecto.Query, warn: false

  alias Plaza.Repo
  alias Plaza.Purchases.Purchase

  def create(attrs) do
    %Purchase{}
    |> Purchase.changeset(attrs)
    |> Repo.insert()
  end
end
