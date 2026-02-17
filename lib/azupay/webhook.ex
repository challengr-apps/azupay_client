defmodule Azupay.Webhook do
  @moduledoc """
  Webhook support for receiving AzuPay payment notifications.

  AzuPay sends webhook notifications when payment entity statuses change
  (PaymentRequest, Payment, PaymentAgreement, PaymentInitiation, etc.).

  ## Transaction-Level Webhooks

  Webhooks are configured per-transaction by setting the `paymentNotification`
  field when creating a request (e.g. via `Azupay.Client.PaymentRequests.create/2`):

    * `paymentNotificationEndpointUrl` — your callback URL
    * `paymentNotificationAuthorizationHeaderValue` — the value AzuPay will send
      in the `Authorization` header

  Since the authorization value is unique per transaction, the plug does **not**
  verify it — your handler must look it up and verify it. See
  `Azupay.Webhook.Handler` for details.

  ## Setup

  Mount the plug once per environment. Each mount receives the environment atom
  in the handler context, so your handler can use the appropriate database or
  config for that environment.

      # In your Phoenix router or Plug.Router
      forward "/webhooks/azupay/uat", Azupay.Webhook.Plug,
        environment: :uat,
        handler: MyApp.AzupayWebhookHandler

      forward "/webhooks/azupay/prod", Azupay.Webhook.Plug,
        environment: :prod,
        handler: MyApp.AzupayWebhookHandler

  ## Handling Events

  Implement the `Azupay.Webhook.Handler` behaviour:

      defmodule MyApp.AzupayWebhookHandler do
        @behaviour Azupay.Webhook.Handler

        @impl true
        def handle_event("PaymentRequest", payload, context) do
          with :ok <- verify_authorization(payload, context) do
            # Process payment request status update
            :ok
          end
        end

        def handle_event(_type, _payload, _context), do: :ok

        defp verify_authorization(payload, %{authorization: auth}) do
          expected = lookup_expected_auth(payload["uniqueReference"])

          if Plug.Crypto.secure_compare(auth || "", expected || "") do
            :ok
          else
            {:error, :unauthorized}
          end
        end
      end

  ## Important Notes

  - Your webhook endpoint must respond within **5 seconds** (AzuPay requirement).
  - AzuPay delivers webhooks **at least once** — handle duplicates gracefully.
  - Webhooks may arrive **out of order** — don't assume sequential delivery.
  - New event types may be added — always handle unknown types gracefully.
  """
end
