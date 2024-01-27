defmodule Plaza.Accounts.UserNotifier do
  import Swoosh.Email

  alias Plaza.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> from({"Plazaaaaa", "plaza@plazaaaaa.com"})
      |> to(recipient)
      |> subject(subject)
      |> text_body(body)

    Mailer.deliver(email)
  end

  def deliver_receipt_to_seller(seller_email, their_share) do
    deliver(seller_email, "Uma venda", """
    Você realizou uma vendaaaaa

    R$ #{(their_share / 100) |> Float.round(2) |> Float.to_string() |> String.replace(".", ",")} estão sendo transferidos para sua conta Stripe.

    Este é um email automatico do site plazaaaaa.com por favor não responder diretamente para este remetente.

    Se não foi você por favor desconsidere esta mensagem.
    """)
  end

  def deliver_receipt_to_buyer(receipt_email, receipt_url) do
    deliver(receipt_email, "Uma compra", """
    Você realizou uma compraaaaa

    O URL do seu pedido: #{receipt_url}

    Este é um email automatico do site plazaaaaa.com por favor não responder diretamente para este remetente.

    Se não foi você por favor desconsidere esta mensagem.
    """)
  end

  @doc """
  Deliver confirmation that the email was confirmed.
  """
  def deliver_confirmation_confirmation(user) do
    deliver(user.email, "Confirmado", """
    Agora sim!

    Seu email foi confirmado.  

    Este é um email automatico do site plazaaaaa.com por favor não responder diretamente para este remetente.

    Se não foi você por favor desconsidere esta mensagem.
    """)
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Bem vindo ao Plaza", """
    Bem vindo ao Plaza,

    Por favor confirme seu email:

    #{url}

    Este é um email automatico do site plazaaaaa.com por favor não responder diretamente para este remetente.

    Se não foi você por favor desconsidere esta mensagem.
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset password instructions", """

    ==============================

    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
