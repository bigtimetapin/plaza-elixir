defmodule Plaza.ProductsTest do
  use Plaza.DataCase

  alias Plaza.Products

  describe "products" do
    alias Plaza.Products.Product

    import Plaza.ProductsFixtures

    @invalid_attrs %{alto: nil, name: nil, price: nil}

    test "list_products/0 returns all products" do
      product = product_fixture()
      assert Products.list_products() == [product]
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      assert Products.get_product!(product.id) == product
    end

    test "create_product/1 with valid data creates a product" do
      valid_attrs = %{alto: true, name: "some name", price: "some price"}

      assert {:ok, %Product{} = product} = Products.create_product(valid_attrs)
      assert product.alto == true
      assert product.name == "some name"
      assert product.price == "some price"
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Products.create_product(@invalid_attrs)
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()
      update_attrs = %{alto: false, name: "some updated name", price: "some updated price"}

      assert {:ok, %Product{} = product} = Products.update_product(product, update_attrs)
      assert product.alto == false
      assert product.name == "some updated name"
      assert product.price == "some updated price"
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = product_fixture()
      assert {:error, %Ecto.Changeset{}} = Products.update_product(product, @invalid_attrs)
      assert product == Products.get_product!(product.id)
    end

    test "delete_product/1 deletes the product" do
      product = product_fixture()
      assert {:ok, %Product{}} = Products.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Products.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset" do
      product = product_fixture()
      assert %Ecto.Changeset{} = Products.change_product(product)
    end
  end

  describe "products" do
    alias Plaza.Products.Product

    import Plaza.ProductsFixtures

    @invalid_attrs %{descr_long: nil, descr_short: nil, name: nil, num_colors: nil, num_expected: nil, product_type: nil}

    test "list_products/0 returns all products" do
      product = product_fixture()
      assert Products.list_products() == [product]
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      assert Products.get_product!(product.id) == product
    end

    test "create_product/1 with valid data creates a product" do
      valid_attrs = %{descr_long: "some descr_long", descr_short: "some descr_short", name: "some name", num_colors: 42, num_expected: 42, product_type: 42}

      assert {:ok, %Product{} = product} = Products.create_product(valid_attrs)
      assert product.descr_long == "some descr_long"
      assert product.descr_short == "some descr_short"
      assert product.name == "some name"
      assert product.num_colors == 42
      assert product.num_expected == 42
      assert product.product_type == 42
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Products.create_product(@invalid_attrs)
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()
      update_attrs = %{descr_long: "some updated descr_long", descr_short: "some updated descr_short", name: "some updated name", num_colors: 43, num_expected: 43, product_type: 43}

      assert {:ok, %Product{} = product} = Products.update_product(product, update_attrs)
      assert product.descr_long == "some updated descr_long"
      assert product.descr_short == "some updated descr_short"
      assert product.name == "some updated name"
      assert product.num_colors == 43
      assert product.num_expected == 43
      assert product.product_type == 43
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = product_fixture()
      assert {:error, %Ecto.Changeset{}} = Products.update_product(product, @invalid_attrs)
      assert product == Products.get_product!(product.id)
    end

    test "delete_product/1 deletes the product" do
      product = product_fixture()
      assert {:ok, %Product{}} = Products.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Products.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset" do
      product = product_fixture()
      assert %Ecto.Changeset{} = Products.change_product(product)
    end
  end
end
