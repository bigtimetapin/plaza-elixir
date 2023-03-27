defmodule Plaza.ProductsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Plaza.Products` context.
  """

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        alto: true,
        name: "some name",
        price: "some price"
      })
      |> Plaza.Products.create_product()

    product
  end
end
