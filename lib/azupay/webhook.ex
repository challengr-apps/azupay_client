defmodule Azupay.Webhook do
  @moduledoc """
  Webhook support for receiving AzuPay payment notifications.

  AzuPay sends webhook notifications when payment entity statuses change
  (PaymentRequest, Payment, PaymentAgreement, PaymentInitiation, etc.).

  ## Authentication Modes

  AzuPay supports two authentication modes for webhooks:

  ### API Key Authentication

  The simpler option — AzuPay sends a static API key in the `Authorization` header.
  Configure per-transaction via the `paymentNotification` field.

      forward "/webhooks/azupay", Azupay.Webhook.Plug,
        auth: {:api_key, "my-webhook-key"},
        handler: MyApp.AzupayWebhookHandler

  ### OAuth2 Authentication

  AzuPay acts as an OAuth2 client: before sending a webhook, it requests a Bearer
  token from your token endpoint using the Client Credentials grant, then sends
  the webhook with that token. You need to mount two plugs:

      # Token endpoint — AzuPay fetches tokens from here
      forward "/webhooks/azupay/token", Azupay.Webhook.TokenEndpoint,
        client_id: "azupay-client",
        client_secret: System.get_env("AZUPAY_WEBHOOK_SECRET"),
        signing_key: System.get_env("WEBHOOK_SIGNING_KEY")

      # Webhook receiver — verifies the Bearer token
      forward "/webhooks/azupay", Azupay.Webhook.Plug,
        auth: {:oauth2, signing_key: System.get_env("WEBHOOK_SIGNING_KEY")},
        handler: MyApp.AzupayWebhookHandler

  The `signing_key` must be the same in both plugs.

  ### Both Modes

  You can accept both API key and OAuth2 webhooks on the same endpoint by
  passing a list of auth methods:

      forward "/webhooks/azupay", Azupay.Webhook.Plug,
        auth: [
          {:api_key, "my-webhook-key"},
          {:oauth2, signing_key: System.get_env("WEBHOOK_SIGNING_KEY")}
        ],
        handler: MyApp.AzupayWebhookHandler

  ## Handling Events

  Implement the `Azupay.Webhook.Handler` behaviour:

      defmodule MyApp.AzupayWebhookHandler do
        @behaviour Azupay.Webhook.Handler

        @impl true
        def handle_event("PaymentRequest", payload) do
          # Handle payment request status update
          :ok
        end

        def handle_event(_type, _payload), do: :ok
      end

  ## Important Notes

  - Your webhook endpoint must respond within **5 seconds** (AzuPay requirement).
  - AzuPay delivers webhooks **at least once** — handle duplicates gracefully.
  - Webhooks may arrive **out of order** — don't assume sequential delivery.
  - New event types may be added — always handle unknown types gracefully.
  """
end
