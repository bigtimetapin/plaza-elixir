defmodule Plaza.Accounts.SellerForm do
  import Ecto.Changeset

  defstruct [
    :user_id,
    :user_name,
    :profile_photo_url,
    :description,
    :location,
    :website,
    :instagram,
    :soundcloud,
    :twitter,
    :stripe_id
  ]

  def from_seller(seller) do
    %{
      user_id: seller.user_id,
      user_name: seller.user_name,
      profile_photo_url: seller.profile_photo_url,
      description: seller.description,
      location: seller.location,
      website: seller.website,
      instagram: maybe_get(seller.socials, :instagram),
      soundcloud: maybe_get(seller.socials, :soundcloud),
      twitter: maybe_get(seller.socials, :twitter),
      stripe_id: seller.stripe_id
    }
  end

  def to_seller(seller_form) do
    %{
      user_id: seller_form.user_id,
      user_name: seller_form.user_name,
      profile_photo_url: seller_form.profile_photo_url,
      description: seller_form.description,
      location: seller_form.location,
      website: seller_form.website,
      socials: %{
        instagram: seller_form.instagram,
        soundcloud: seller_form.soundcloud,
        twitter: seller_form.twitter
      },
      stripe_id: seller_form.stripe_id
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
      :user_name,
      :website,
      :instagram,
      :soundcloud,
      :twitter
    ])
    |> validate_required([
      :user_name
    ])
    |> validate_length(:instagram, min: 1)
    |> validate_length(:soundcloud, min: 1)
    |> validate_length(:twitter, min: 1)
  end

  defp types() do
    %{
      user_name: :string,
      website: :string,
      instagram: :string,
      soundcloud: :string,
      twitter: :string
    }
  end
end
