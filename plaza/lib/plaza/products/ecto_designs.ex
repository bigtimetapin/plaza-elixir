defmodule Plaza.Products.EctoDesigns do
  use Ecto.Type
  def type, do: :map

  alias Plaza.Products.Designs

  @fields [:front, :back, :display]

  def cast(%Designs{} = data), do: {:ok, data}

  def cast(data) when is_map(data) do
    {:ok, struct(Designs, data)}
  end

  def cast(_), do: :error

  def load(data) when is_map(data) do
    data =
      for {key, val} <- data do
        {String.to_existing_atom(key), val}
      end

    {:ok, struct(Designs, data)}
  end

  def dump(%Designs{} = data), do: {:ok, Map.from_struct(data)}
  def dump(_), do: :error
end
