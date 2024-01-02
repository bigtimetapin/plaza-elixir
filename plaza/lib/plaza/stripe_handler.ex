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

    transfer_tasks =
      Task.async_stream(
        purchase.sellers,
        fn %{
             "user_id" => user_id,
             "total_price" => total_price,
             "total_quantity" => total_quantity
           } = params ->
          # 50 * 100 cents
          platform_fee = 5000

          amount =
            Product.price_unit_amount(%{price: total_price}) - platform_fee * total_quantity

          seller = Accounts.get_seller_by_id(user_id)

          transfer_result =
            Stripe.Transfer.create(%{
              amount: amount,
              currency: "brl",
              destination: seller.stripe_id,
              source_transaction: charge.id
            })

          ## TODO; write paid to db, record level and top level
          case transfer_result do
            {:ok, _} ->
              %{params | "paid" => true}

            {:error, error} ->
              IO.inspect(error)
              params
          end
        end
      )

    transfers = Enum.to_list(transfer_tasks)
    IO.inspect(transfers)

    :ok
  end
end
