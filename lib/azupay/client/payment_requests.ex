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

  @doc """
  Retrieves a payment request by ID.

  ## Examples

      {:ok, payment_request} = Azupay.Client.PaymentRequests.get(client, "pr-123")
  """
  @spec get(Client.t(), String.t()) :: Request.response()
  def get(client, id) do
    Request.get(client, "/paymentRequest", params: [id: id])
  end

  @doc """
  Deletes a payment request by ID.

  ## Examples

      {:ok, _} = Azupay.Client.PaymentRequests.delete(client, "pr-123")
  """
  @spec delete(Client.t(), String.t()) :: Request.response()
  def delete(client, id) do
    Request.delete(client, "/paymentRequest", params: [id: id])
  end

  @doc """
  Refunds a payment request.

  Performs a full refund by default. Pass `refund_amount` for a partial refund.

  ## Examples

      # Full refund
      {:ok, _} = Azupay.Client.PaymentRequests.refund(client, "pr-123")

      # Partial refund
      {:ok, _} = Azupay.Client.PaymentRequests.refund(client, "pr-123", refund_amount: "5.00")
  """
  @spec refund(Client.t(), String.t(), keyword()) :: Request.response()
  def refund(client, id, opts \\ []) do
    params =
      case Keyword.get(opts, :refund_amount) do
        nil -> [id: id]
        amount -> [id: id, refundAmount: amount]
      end

    Request.post(client, "/paymentRequest/refund", params: params)
  end

  @doc """
  Searches for payment requests.

  The params map is automatically wrapped in the required `"PaymentRequestSearch"` envelope.

  Note: `clientTransactionId` and `clientBranch` cannot be included with other fields.
  `payID` can be included with dates but not with other fields.

  ## Search fields

    * `clientTransactionId` - Unique merchant transaction ID (5-100 chars)
    * `payID` - PayID email address
    * `clientBranch` - Client branch identifier
    * `fromDate` - Start of date range (UTC, ISO 8601)
    * `toDate` - End of date range (UTC, ISO 8601)

  ## Pagination

    * `nextPageId` - Pagination cursor from a previous search result
    * `numberOfRecords` - Number of records to retrieve (default 100)

  These pagination params are automatically extracted from the body and sent as query params.

  ## Examples

      {:ok, results} = Azupay.Client.PaymentRequests.search(client, %{
        "clientTransactionId" => "txn-123"
      })

      # With pagination
      {:ok, results} = Azupay.Client.PaymentRequests.search(client, %{
        "clientTransactionId" => "txn-123",
        "nextPageId" => "page-2",
        "numberOfRecords" => 50
      })
  """
  @spec search(Client.t(), map()) :: Request.response()
  def search(client, params) when is_map(params) do
    {query, body} = Request.extract_search_params(params)

    Request.post(client, "/paymentRequest/search",
      json: %{"PaymentRequestSearch" => body},
      params: query
    )
  end
end
