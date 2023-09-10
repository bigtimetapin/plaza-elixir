defmodule Plaza.Products.EctoMocks do
  use Ecto.Type
  def type, do: :map

  alias Plaza.Products.Mocks

  def cast(data) when is_map(data) do
    {:ok, struct(Mocks, data)}
  end

  def cast(%Mocks{} = data), do: {:ok, data}

  def cast(_), do: :error

  def load(data) when is_map(data) do
    data =
      for {key, val} <- data do
        {String.to_existing_atom(key), val}
      end

    {:ok, struct(Mocks, data)}
  end

  def dump(%Mocks{} = data), do: {:ok, Map.from_struct(data)}
  def dump(_), do: :error
end
