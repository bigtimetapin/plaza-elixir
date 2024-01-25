defmodule Plaza.Products do
  @moduledoc """
  The Products context.
  """

  import Ecto.Query, warn: false
  alias Plaza.Repo

  alias Plaza.Products.Product

  def top_10 do
    Repo.all(
      from Product,
        where: [active: true],
        order_by: [desc: :updated_at],
        limit: 10
    )
  end

  def top_3_other_products(%{id: id, user_id: user_id} = _product) do
    Repo.all(
      from p in Product,
        where: [active: true, user_id: ^user_id],
        where: p.id != ^id,
        order_by: [desc: :updated_at],
        limit: 3
    )
  end

  def top_4_paginated(cursors) do
    %{entries: entries, metadata: metadata} =
      Repo.paginate(
        from(
          p in Product,
          where: [active: true, curated: true],
          order_by: [desc: :updated_at, desc: :id]
        ),
        before: cursors.before,
        after: cursors.after,
        cursor_fields: [{:updated_at, :desc}, {:id, :desc}],
        limit: 4
      )

    %{entries: entries, metadata: metadata}
  end

  def top_8_uncurated_paginated(cursors) do
    %{entries: entries, metadata: metadata} =
      Repo.paginate(
        from(
          p in Product,
          where: [active: true, curated: false],
          order_by: [desc: :updated_at, desc: :id]
        ),
        before: cursors.before,
        after: cursors.after,
        cursor_fields: [{:updated_at, :desc}, {:id, :desc}],
        limit: 8
      )

    %{entries: entries, metadata: metadata}
  end

  def all_in_list(product_ids) do
    Repo.all(
      from p in Product,
        where: p.id in ^product_ids
    )
  end

  def count(id) do
    Repo.aggregate(
      from(Product, where: [user_id: ^id]),
      :count
    )
  end

  def expire_products do
    now = NaiveDateTime.utc_now()

    from(p in Product,
      where: p.campaign_duration_timestamp < ^now and p.active == true
    )
    |> Repo.update_all(set: [active: false])
  end

  def activate_product(product) do
    campaign_duration_timestamp =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(product.campaign_duration, :day)
      |> NaiveDateTime.truncate(:second)

    update_product(
      product,
      %{
        "campaign_duration_timestamp" => campaign_duration_timestamp,
        "active" => true
      }
    )
  end

  def curate_product(product) do
    update_product(
      product,
      %{"curated" => true}
    )
  end

  def uncurate_product(product) do
    update_product(
      product,
      %{"curated" => false}
    )
  end

  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products()
      [%Product{}, ...]

  """
  def list_products do
    Repo.all(Product)
  end

  def list_products_by_user_id(id) do
    Repo.all(
      from Product,
        where: [user_id: ^id],
        order_by: [desc: :updated_at]
    )
  end

  def list_products_by_user_id(id, n) do
    Repo.all(
      from Product,
        where: [user_id: ^id],
        order_by: [desc: :updated_at],
        limit: ^n
    )
  end

  def list_active_products_by_user_id(id) do
    Repo.all(
      from Product,
        where: [user_id: ^id, active: true],
        order_by: [desc: :updated_at]
    )
  end

  def list_active_products_by_user_id(id, n) do
    Repo.all(
      from Product,
        where: [user_id: ^id, active: true],
        order_by: [desc: :updated_at],
        limit: ^n
    )
  end

  @doc """
  Gets a single product.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product!(123)
      %Product{}

      iex> get_product!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(id), do: Repo.get!(Product, id)

  def get_product(id), do: Repo.get(Product, id)

  def get_product(seller_id, product_name) do
    Repo.get_by(Product, user_id: seller_id, name: product_name)
  end

  def create_product(%Product{} = product) do
    product
    |> Product.changeset(%{})
    |> Repo.insert()
  end

  @doc """
  Creates a product.

  ## Examples

      iex> create_product(%{field: value})
      {:ok, %Product{}}

      iex> create_product(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a product.

  ## Examples

      iex> update_product(product, %{field: new_value})
      {:ok, %Product{}}

      iex> update_product(product, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a product.

  ## Examples

      iex> delete_product(product)
      {:ok, %Product{}}

      iex> delete_product(product)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product changes.

  ## Examples

      iex> change_product(product)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end
end
