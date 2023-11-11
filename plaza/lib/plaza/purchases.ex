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

  def normalize_payment_status(status) do
    case status do
      "succeeded" -> status
      "canceled" -> status
      "processing" -> status
      _ -> "error"
    end
  end
end
