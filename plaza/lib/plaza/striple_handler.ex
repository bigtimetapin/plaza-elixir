defmodule Plaza.StripeHandler do
  @behaviour Stripe.WebhookHandler

  alias Plaza.Purchases

  @impl true
  def handle_event(%Stripe.Event{
        type: "checkout.session.completed",
        data: %{object: stripe_session}
      }) do
    ## IO.inspect(stripe_session)
    ## purchase_id = stripe_session.client_reference_id
    ## {:ok, payment_intent} = Stripe.PaymentIntent.retrieve(stripe_session.payment_intent, %{})
    ## payment_status = Purchases.normalize_payment_status(payment_intent.status)

    ## Phoenix.PubSub.broadcast(
    ##   Plaza.PubSub,
    ##   "payment-status-#{purchase_id}",
    ##   {:payment_status, payment_status}
    ## )

    :ok
  end

  def handle_event(%Stripe.Event{type: "payment_intent.succeeded"} = event) do
    IO.inspect(event)
    :ok
  end

  # Return HTTP 200 for unhandled events
  def handle_event(%Stripe.Event{type: type}) do
    IO.inspect(type)
    :ok
  end
end
