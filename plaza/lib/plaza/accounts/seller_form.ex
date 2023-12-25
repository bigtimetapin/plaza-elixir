defmodule Plaza.Accounts.SellerForm do
  import Ecto.Changeset

  alias Plaza.Accounts.Seller
  alias Plaza.Accounts.Socials

  defstruct [
    :id,
    :user_id,
    :user_name,
    :profile_photo_url,
    :description,
    :location,
    :website,
    :instagram,
    :soundcloud,
    :twitter,
    :stripe_id,
    :inserted_at,
    :updated_at
  ]

  def from_seller(seller) do
    %__MODULE__{
      id: seller.id,
      user_id: seller.user_id,
      user_name: seller.user_name,
      profile_photo_url: seller.profile_photo_url,
      description: seller.description,
      location: seller.location,
      website: seller.website,
      instagram: maybe_get(seller.socials, :instagram),
      soundcloud: maybe_get(seller.socials, :soundcloud),
      twitter: maybe_get(seller.socials, :twitter),
      stripe_id: seller.stripe_id,
      inserted_at: seller.inserted_at,
      updated_at: seller.updated_at
    }
  end

  def to_seller(seller_form) do
    %Seller{
      id: seller_form.id,
      user_id: seller_form.user_id,
      user_name: seller_form.user_name,
      profile_photo_url: seller_form.profile_photo_url,
      description: seller_form.description,
      location: seller_form.location,
      website: seller_form.website,
      socials: %Socials{
        instagram: seller_form.instagram,
        soundcloud: seller_form.soundcloud,
        twitter: seller_form.twitter
      },
      stripe_id: seller_form.stripe_id,
      inserted_at: seller_form.inserted_at,
      updated_at: seller_form.updated_at
    }
  end

  defp maybe_get(map, field) do
    case map do
      nil -> nil
      _ -> Map.get(map, field)
    end
  end

  def changeset(seller_form, attrs) do
    {seller_form, types()}
    |> cast(attrs, [
      :id,
      :user_id,
      :user_name,
      :profile_photo_url,
      :description,
      :location,
      :website,
      :instagram,
      :soundcloud,
      :twitter,
      :stripe_id,
      :inserted_at,
      :updated_at
    ])
    |> validate_required([
      :user_id,
      :user_name
    ])
  end

  defp types() do
    %{
      id: :id,
      user_id: :id,
      user_name: :string,
      profile_photo_url: :string,
      description: :string,
      location: :string,
      website: :string,
      instagram: :string,
      soundcloud: :string,
      twitter: :string,
      stripe_id: :string,
      inserted_at: :naive_datetime,
      updated_at: :naive_datetime
    }
  end
end
