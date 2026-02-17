defmodule Azupay.Webhook.Handler do
  @moduledoc """
  Behaviour for handling AzuPay webhook events.

  Implement `handle_event/3` to process incoming webhook notifications.
  The event type is extracted from the payload and passed as the first argument,
  along with a context map containing the environment and raw `Authorization`
  header value.

  Your handler is responsible for verifying the `Authorization` header against
  the value you stored when creating the transaction (the
  `paymentNotificationAuthorizationHeaderValue` field). Return
  `{:error, :unauthorized}` to reject the request with a 401 response.

  ## Example

      defmodule MyApp.AzupayWebhookHandler do
        @behaviour Azupay.Webhook.Handler

        @impl true
        def handle_event("PaymentRequest", payload, context) do
          with :ok <- verify_authorization(payload, context) do
            # Process payment request status change
            :ok
          end
        end

        def handle_event(_type, _payload, _context) do
          # Gracefully ignore unknown event types
          :ok
        end

        defp verify_authorization(payload, %{authorization: auth}) do
          expected = lookup_expected_auth(payload["uniqueReference"])

          if Plug.Crypto.secure_compare(auth || "", expected || "") do
            :ok
          else
            {:error, :unauthorized}
          end
        end
      end

  ## Event Types

  AzuPay sends notifications for these entity types:

    * `"PaymentRequest"` — Payment request status updates
    * `"Payment"` — Payment disbursement status updates
    * `"PaymentAgreement"` — PayTo agreement status updates
    * `"PaymentInitiation"` — Payment initiation status updates
    * `"SweepRequest"` — Sweep request status updates
    * `"ClientEnabled"` — Client enabled events

  New event types may be added by AzuPay — always handle unknown types gracefully.

  ## Context

  The `context` map contains:

    * `:environment` — The environment atom (e.g. `:uat` or `:prod`) from the plug config
    * `:authorization` — The raw `Authorization` header value from the request, or `nil` if absent
  """

  @doc """
  Called when a webhook event is received from AzuPay.

  Returns `:ok` to acknowledge the event, `{:error, :unauthorized}` to reject
  with a 401 response, or `{:error, reason}` if processing fails (500 response).
  """
  @callback handle_event(event_type :: String.t(), payload :: map(), context :: map()) ::
              :ok | {:error, :unauthorized} | {:error, term()}
end
