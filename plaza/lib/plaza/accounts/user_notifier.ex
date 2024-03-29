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

  def deliver_admin_notice_of_product_upload(product) do
    artist_href = URI.encode_query(%{"user_name" => product.user_name})
    artist_href = "https://plazaaaaa.com/artist?#{artist_href}"
    product_href = URI.encode_query(%{"product-id" => product.id})
    product_href = "https://plazaaaaa.com/product?#{product_href}"

    deliver("admin@plazaaaaa.com", "Product Upload", """
    Product uploaded
    by: #{artist_href}
    product: #{product_href} 
    """)
  end

  def deliver_admin_notice_of_login(email) do
    deliver("admin@plazaaaaa.com", "User Login", """
    User logged in with email: #{email}
    """)
  end

  def deliver_newsletter_registration(email) do
    deliver(email, "Confirmado", """
    Bem vindo ao Plaza Newsletter,

    Seu email foi cadastrado com sucesso.

    Este é um email automatico do site plazaaaaa.com por favor não responder diretamente para este remetente.

    Se não foi você por favor desconsidere esta mensagem.
    """)
  end

  def deliver_receipt_to_seller(seller_email, their_share) do
    deliver(seller_email, "Uma venda", """
    Você realizou uma vendaaaaa

    R$ #{(their_share / 100) |> Float.round(2) |> Float.to_string() |> String.replace(".", ",")} estão sendo transferidos para sua conta Stripe.

    Visite plazaaaaa.com/my-store para mais detalhes.

    Este é um email automatico do site plazaaaaa.com por favor não responder diretamente para este remetente.

    Se não foi você por favor desconsidere esta mensagem.
    """)
  end

  def deliver_receipt_to_buyer(receipt_email, receipt_url) do
    deliver(receipt_email, "Uma compra", """
    Você realizou uma compraaaaa

    O recibo do seu pedido: #{receipt_url}

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
