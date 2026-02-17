defmodule Azupay.Client.Payments do
  @moduledoc """
  Payment resource operations for the AzuPay API.

  Payments allow you to disburse funds via PayID or BSB/account number.

  ## Required fields

    * `clientPaymentId` - Unique identifier to correlate with your system
    * `payeeName` - Account holder's name
    * `paymentAmount` - Amount as a string (e.g. "100.00")
    * `paymentDescription` - Description shown on payee's bank statement

  ## PayID payment (one of):

    * `payID` - The PayID identifier
    * `payIDType` - Type: EMAIL, PHONE, ABN, or ORG

  ## BSB payment (one of):

    * `bsb` - Bank State Branch code
    * `accountNumber` - Account number
  """

  alias Azupay.Client
  alias Azupay.Client.Request

  @doc """
  Makes a payment.

  The params map is automatically wrapped in the required `"Payment"` envelope.

  ## Examples

      # PayID payment
      {:ok, payment} = Azupay.Client.Payments.create(client, %{
        "clientPaymentId" => "pay-001",
        "payeeName" => "Jane Smith",
        "payID" => "jane@example.com",
        "payIDType" => "EMAIL",
        "paymentAmount" => "100.00",
        "paymentDescription" => "Invoice payment"
      })

      # BSB payment
      {:ok, payment} = Azupay.Client.Payments.create(client, %{
        "clientPaymentId" => "pay-002",
        "payeeName" => "Jane Smith",
        "bsb" => "123456",
        "accountNumber" => "9876543",
        "paymentAmount" => "100.00",
        "paymentDescription" => "Invoice payment"
      })
  """
  @spec create(Client.t(), map()) :: Request.response()
  def create(client, params) when is_map(params) do
    Request.post(client, "/payment", json: %{"Payment" => params})
  end

  @doc """
  Retrieves a payment by ID.

  ## Examples

      {:ok, payment} = Azupay.Client.Payments.get(client, "payment-123")
  """
  @spec get(Client.t(), String.t()) :: Request.response()
  def get(client, id) do
    Request.get(client, "/payment", params: [id: id])
  end

  @doc """
  Searches for payments.

  The params map is automatically wrapped in the required `"PaymentSearch"` envelope.

  ## Search fields

    * `clientPaymentId` - Unique payment ID from your system (5-100 chars)
    * `fromDate` - Start of date range (UTC, ISO 8601)
    * `toDate` - End of date range (UTC, ISO 8601)

  ## Pagination

    * `nextPageId` - Pagination cursor from a previous search result
    * `numberOfRecords` - Number of records to retrieve (default 100)

  These pagination params are automatically extracted from the body and sent as query params.

  ## Examples

      {:ok, results} = Azupay.Client.Payments.search(client, %{
        "clientPaymentId" => "pay-001"
      })

      # With pagination
      {:ok, results} = Azupay.Client.Payments.search(client, %{
        "clientPaymentId" => "pay-001",
        "nextPageId" => "page-2",
        "numberOfRecords" => 50
      })
  """
  @spec search(Client.t(), map()) :: Request.response()
  def search(client, params) when is_map(params) do
    {query, body} = Request.extract_search_params(params)

    Request.post(client, "/payment/search",
      json: %{"PaymentSearch" => body},
      params: query
    )
  end
end
