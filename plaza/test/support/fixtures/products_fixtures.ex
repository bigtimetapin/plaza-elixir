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

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        descr_long: "some descr_long",
        descr_short: "some descr_short",
        name: "some name",
        num_colors: 42,
        num_expected: 42,
        product_type: 42
      })
      |> Plaza.Products.create_product()

    product
  end
end
