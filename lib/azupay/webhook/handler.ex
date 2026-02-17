defmodule Azupay.Webhook.Handler do
  @moduledoc """
  Behaviour for handling AzuPay webhook events.

  Implement `handle_event/2` to process incoming webhook notifications.
  The event type is extracted from the payload and passed as the first argument.

  ## Example

      defmodule MyApp.AzupayWebhookHandler do
        @behaviour Azupay.Webhook.Handler

        @impl true
        def handle_event("PaymentRequest", payload) do
          status = payload["status"]
          # Process payment request status change
          :ok
        end

        def handle_event("Payment", payload) do
          # Process payment status change
          :ok
        end

        def handle_event(_type, _payload) do
          # Gracefully ignore unknown event types
          :ok
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
  """

  @doc """
  Called when a webhook event is received from AzuPay.

  Returns `:ok` to acknowledge the event, or `{:error, reason}` if processing fails.
  """
  @callback handle_event(event_type :: String.t(), payload :: map()) :: :ok | {:error, term()}
end
