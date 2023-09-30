defmodule Plaza.Accounts.EctoSocials do
  use Ecto.Type
  def type, do: :map

  alias Plaza.Accounts.Socials

  def cast(%Socials{} = data), do: {:ok, data}

  def cast(data) when is_map(data) do
    {:ok, struct(Socials, data)}
  end

  def cast(_), do: :error

  def load(data) when is_map(data) do
    data =
      for {key, val} <- data do
        {String.to_existing_atom(key), val}
      end

    {:ok, struct(Socials, data)}
  end

  def dump(%Socials{} = data), do: {:ok, Map.from_struct(data)}
  def dump(_), do: :error
end
