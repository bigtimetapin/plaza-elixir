defmodule Plaza.Repo do
  use Ecto.Repo,
    otp_app: :plaza,
    adapter: Ecto.Adapters.Postgres
end
