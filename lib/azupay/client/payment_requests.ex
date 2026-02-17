defmodule Azupay.Client.PaymentRequests do
  @moduledoc """
  Payment Request resource operations for the AzuPay API.

  Payment Requests generate PayID or virtual account details for receiving
  payments via the NPP (New Payments Platform).

  ## Required fields

    * `clientTransactionId` - Unique merchant transaction ID (3-100 chars)
    * `paymentDescription` - Description shown in banking interface (5-140 chars)

  ## Optional fields

    * `clientId` - Defaults to the value from client configuration; pass to override
    * `payID` - Unique email PayID (auto-generated if omitted)
    * `payIDSuffix` - Email domain for auto-generated PayID
    * `paymentAmount` - Amount in AUD (min 0.01)
    * `multiPayment` - Allow multiple payments (boolean)
    * `paymentExpiryDatetime` - ISO 8601 expiry time
    * `suggestedPayerDetails` - Pre-fill payer information
    * `payerNotificationEmail` - Email for payer notifications
    * `payerNotificationMobile` - Mobile for payer notifications (+61 format)
    * `enableVirtualAccount` - Enable virtual BSB/account number (boolean)
    * `metaData` - Arbitrary metadata object
    * `paymentNotification` - Webhook configuration
  """

  alias Azupay.Client
  alias Azupay.Client.Request

  @doc """
  Creates a new payment request.

  The params map is automatically wrapped in the required `"PaymentRequest"` envelope.

  ## Examples

      {:ok, payment_request} = Azupay.Client.PaymentRequests.create(client, %{
        "clientTransactionId" => "txn-unique-123",
        "paymentDescription" => "Invoice #1234 payment"
      })

      # With optional fields
      {:ok, payment_request} = Azupay.Client.PaymentRequests.create(client, %{
        "payID" => "unique-payid@yourdomain.com.au",
        "clientTransactionId" => "txn-unique-456",
        "paymentDescription" => "Monthly subscription",
        "paymentAmount" => 29.99,
        "paymentExpiryDatetime" => "2026-03-01T00:00:00+11:00"
      })
  """
  @spec create(Client.t(), map()) :: Request.response()
  def create(client, params) when is_map(params) do
    params = Map.put_new(params, "clientId", client.client_id)
    Request.post(client, "/paymentRequest", json: %{"PaymentRequest" => params})
  end
end
