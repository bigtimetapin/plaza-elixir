defmodule Plaza.Accounts.Address do
  defstruct street: :string,
            number: :string,
            city: :string,
            state: :string,
            zipcode: :string,
            neighborhood: :string,
            country: :string
end
