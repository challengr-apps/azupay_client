defmodule Azupay.Client.PaymentInitiations do
  @moduledoc """
  Payment Initiation (PayTo) resource operations for the AzuPay API.

  Payment Initiations are used to collect funds from payers who have
  an active Payment Agreement in place.
  """

  alias Azupay.Client
  alias Azupay.Client.Request

  @doc """
  Initiates a payment against an active payment agreement.

  The params map is automatically wrapped in the required `"PaymentInitiation"` envelope.

  ## Examples

      {:ok, initiation} = Azupay.Client.PaymentInitiations.create(client, %{
        "clientId" => "CLIENT1",
        "paymentAgreementId" => "agreement-id",
        "clientTransactionId" => "tx-pmt-001",
        "paymentAmount" => "75.50",
        "description" => "December subscription"
      })
  """
  @spec create(Client.t(), map()) :: Request.response()
  def create(client, params) when is_map(params) do
    Request.post(client, "/paymentInitiation", json: %{"PaymentInitiation" => params})
  end

  @doc """
  Retrieves a payment initiation by ID.

  ## Examples

      {:ok, initiation} = Azupay.Client.PaymentInitiations.get(client, "initiation-123")
  """
  @spec get(Client.t(), String.t()) :: Request.response()
  def get(client, id) do
    Request.get(client, "/paymentInitiation", params: [id: id])
  end

  @doc """
  Refunds a payment initiation.

  Performs a full refund by default. Pass `refund_amount` for a partial refund.

  ## Options

    * `:refund_amount` - Amount to refund (omit for full refund)
    * `:refund_batch_id` - Batch ID if the refund is done through batch

  ## Examples

      # Full refund
      {:ok, _} = Azupay.Client.PaymentInitiations.refund(client, "initiation-123")

      # Partial refund
      {:ok, _} = Azupay.Client.PaymentInitiations.refund(client, "initiation-123", refund_amount: "25.00")
  """
  @spec refund(Client.t(), String.t(), keyword()) :: Request.response()
  def refund(client, id, opts \\ []) do
    params =
      [id: id]
      |> maybe_add(:refundAmount, Keyword.get(opts, :refund_amount))
      |> maybe_add(:refundBatchId, Keyword.get(opts, :refund_batch_id))

    Request.post(client, "/paymentInitiation/refund", params: params)
  end

  @doc """
  Searches for payment initiations.

  The params map is automatically wrapped in the required `"PaymentInitiationSearch"` envelope.

  Note: `clientTransactionId` and date fields cannot be included in the same request.

  ## Search fields

    * `clientTransactionId` - Unique merchant transaction ID (5-100 chars)
    * `fromDate` - Start of date range (UTC, ISO 8601)
    * `toDate` - End of date range (UTC, ISO 8601)

  ## Pagination

    * `nextPageId` - Pagination cursor from a previous search result
    * `numberOfRecords` - Number of records to retrieve (default 100)

  These pagination params are automatically extracted from the body and sent as query params.

  ## Examples

      {:ok, results} = Azupay.Client.PaymentInitiations.search(client, %{
        "clientTransactionId" => "tx-pmt-001"
      })

      # With pagination
      {:ok, results} = Azupay.Client.PaymentInitiations.search(client, %{
        "clientTransactionId" => "tx-pmt-001",
        "nextPageId" => "page-2",
        "numberOfRecords" => 50
      })
  """
  @spec search(Client.t(), map()) :: Request.response()
  def search(client, params) when is_map(params) do
    {query, body} = Request.extract_search_params(params)

    Request.post(client, "/paymentInitiation/search",
      json: %{"PaymentInitiationSearch" => body},
      params: query
    )
  end

  defp maybe_add(params, _key, nil), do: params
  defp maybe_add(params, key, value), do: Keyword.put(params, key, value)
end
