defmodule Plaza.Dimona.Config do
  def get() do
    System.fetch_env!("DIMONA_API_KEY")
  end
end
