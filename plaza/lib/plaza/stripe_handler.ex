defmodule Plaza.StripeHandler do
  @behaviour Stripe.WebhookHandler

  alias Plaza.Accounts
  alias Plaza.Products.Product
  alias Plaza.Purchases

  ## TODO: send email to buyer 
  @impl true
  def handle_event(%Stripe.Event{type: "payment_intent.succeeded", data: data}) do
    Task.Supervisor.start_child(Plaza.TaskSupervisor, fn ->
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
               "total_platform_fee" => total_platform_fee
             } = params ->
            amount =
              Product.price_unit_amount(%{price: total_price}) -
                Product.price_unit_amount(%{price: total_platform_fee})

            seller = Accounts.get_seller_by_id(user_id)

            transfer_result =
              Stripe.Transfer.create(%{
                amount: amount,
                currency: "brl",
                destination: seller.stripe_id,
                source_transaction: charge.id
              })

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
      sellers_paid = Enum.all?(transfers, fn el -> validate_paid(el) end)
      sellers = Enum.map(transfers, fn {_, seller} -> seller end)
      IO.inspect(sellers)

      Purchases.update(
        purchase,
        %{"sellers" => sellers, "sellers_paid" => sellers_paid}
      )
    end)

    :ok
  end

  defp validate_paid({:ok, %{"paid" => true}}) do
    true
  end

  defp validate_paid(_) do
    false
  end
end
