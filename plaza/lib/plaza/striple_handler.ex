defmodule Plaza.StripeHandler do
  @behaviour Stripe.WebhookHandler

  alias Plaza.Purchases
  alias Plaza.Accounts.UserNotifier

  @impl true
  def handle_event(%Stripe.Event{type: "payment_intent.succeeded", data: data}) do
    %{object: %{metadata: %{"purchase_id" => purchase_id}}} = data
    IO.inspect(purchase_id)

    Phoenix.PubSub.broadcast(
      Plaza.PubSub,
      "payment-status-#{purchase_id}",
      {:payment_status, "succeeded"}
    )

    purchase = Purchases.get!(purchase_id)
    IO.inspect(purchase)

    response = UserNotifier.deliver_quick(%{email: purchase.email})

    IO.inspect(response)

    :ok
  end
end
