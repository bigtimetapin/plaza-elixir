defmodule Plaza.StripeHandler do
  @behaviour Stripe.WebhookHandler

  alias Plaza.Accounts
  alias Plaza.Products
  alias Plaza.Products.Product
  alias Plaza.Purchases

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
    {:ok, stripe_session} = Stripe.Session.retrieve(purchase.stripe_session_id)

    {:ok, payment_intent} = Stripe.PaymentIntent.retrieve(stripe_session.payment_intent, %{})

    charge = List.first(payment_intent.charges.data)

    IO.inspect(charge)
    IO.inspect(purchase.products)

    transfer_tasks =
      Task.async_stream(
        purchase.products,
        fn %{"product_id" => product_id, "quantity" => quantity} ->
          product = Products.get_product(product_id)
          amount = (Product.price_unit_amount(product) - 5000) * quantity
          seller = Accounts.get_seller_by_id(product.user_id)

          {:ok, transfer} =
            Stripe.Transfer.create(%{
              amount: amount,
              currency: "brl",
              destination: seller.stripe_id,
              source_transaction: charge.id
            })
        end
      )

    transfers = Enum.to_list(transfer_tasks)
    IO.inspect(transfers)

    :ok
  end
end
