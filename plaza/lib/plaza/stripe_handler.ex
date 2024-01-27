defmodule Plaza.StripeHandler do
  @behaviour Stripe.WebhookHandler

  alias Plaza.Accounts
  alias Plaza.Accounts.UserNotifier
  alias Plaza.Products.Product
  alias Plaza.Purchases
  alias Plaza.Dimona.Requests.Order

  @impl true
  def handle_event(%Stripe.Event{type: "payment_intent.succeeded", data: data}) do
    Task.Supervisor.start_child(Plaza.TaskSupervisor, fn ->
      %{object: %{metadata: %{"purchase_id" => purchase_id}}} = data

      ## send message to src liveview 
      ## in off chance that their url reload beat stripe
      Phoenix.PubSub.broadcast(
        Plaza.PubSub,
        "payment-status-#{purchase_id}",
        {:payment_status, "succeeded"}
      )

      ## fetch stripe transaction info
      purchase = Purchases.get!(purchase_id)
      {:ok, stripe_session} = Stripe.Session.retrieve(purchase.stripe_session_id)

      {:ok, payment_intent} = Stripe.PaymentIntent.retrieve(stripe_session.payment_intent, %{})

      charge = List.first(payment_intent.charges.data)
      ## email receipt to buyer
      buyer_email_response =
        UserNotifier.deliver_receipt_to_buyer(
          charge.receipt_email,
          charge.receipt_url
        )

      IO.inspect(buyer_email_response)

      ## build transfer payment to sellers
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

            user = Accounts.get_user!(user_id)
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
                seller_email_response =
                  UserNotifier.deliver_receipt_to_seller(
                    user.email,
                    amount
                  )

                IO.inspect(seller_email_response)
                %{params | "paid" => true}

              {:error, error} ->
                IO.inspect(error)
                params
            end
          end
        )

      ## fire off transfer payments
      transfers = Enum.to_list(transfer_tasks)
      ## payment analytics
      sellers_paid = Enum.all?(transfers, fn el -> validate_paid(el) end)
      sellers = Enum.map(transfers, fn {_, seller} -> seller end)
      IO.inspect(sellers)
      ## build and fire off order create to dimona 
      dimona_order = purchase |> Order.build()
      IO.inspect("here 01")

      dimona_result =
        case dimona_order do
          {:ok, body} ->
            IO.inspect("here 02")
            body |> Order.post()

          :error ->
            IO.inspect("here 03")
            :error
        end

      case dimona_result do
        {:ok, body} ->
          IO.inspect("here 04")
          IO.inspect(body)

        error ->
          IO.inspect("here 05")
          IO.inspect(error)
      end

      ## persist analytics 
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
