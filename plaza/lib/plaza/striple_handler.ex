defmodule Plaza.StripeHandler do
  @behaviour Stripe.WebhookHandler

  @impl true
  def handle_event(%Stripe.Event{type: "checkout.session.completed"} = event) do
    IO.inspect("Checkout Session Completed")
    IO.inspect(event)
    # Payment is successful and the subscription is created.
    # You should provision the subscription and save the customer ID to your database.
    :ok
  end

  # Return HTTP 200 for unhandled events
  @impl true
  def handle_event(event) do
    IO.inspect(event)
    :ok
  end
end
