defmodule Plaza.StripeHandler do
  @behaviour Stripe.WebhookHandler

  alias Plaza.Purchases

  ## @impl true
  ## def handle_event(%Stripe.Event{type: "payment_intent.succeeded"} = event) do
  ##   IO.inspect(event)

  ##   ## IO.inspect(stripe_session)
  ##   ## purchase_id = stripe_session.client_reference_id
  ##   ## {:ok, payment_intent} = Stripe.PaymentIntent.retrieve(stripe_session.payment_intent, %{})
  ##   ## payment_status = Purchases.normalize_payment_status(payment_intent.status)

  ##   ## Phoenix.PubSub.broadcast(
  ##   ##   Plaza.PubSub,
  ##   ##   "payment-status-#{purchase_id}",
  ##   ##   {:payment_status, payment_status}
  ##   ## )
  ##   :ok
  ## end

  # Return HTTP 200 for unhandled events
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

    :ok
  end
end
