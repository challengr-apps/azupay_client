defmodule Azupay.Client.PaymentAgreements do
  @moduledoc """
  Payment Agreement (PayTo) resource operations for the AzuPay API.

  Payment Agreements allow merchants to set up recurring payment mandates
  with payers via the PayTo network.
  """

  alias Azupay.Client
  alias Azupay.Client.Request

  @doc """
  Creates a new payment agreement.

  The params map is automatically wrapped in the required `"PaymentAgreement"` envelope.

  ## Examples

      {:ok, agreement} = Azupay.Client.PaymentAgreements.create(client, %{
        "clientId" => "CLIENT1",
        "clientTransactionId" => "tx-agr-001",
        "contractId" => "CONTRACT-12345",
        "payerDetails" => %{
          "name" => "Jane Smith",
          "type" => "Person",
          "payIDDetails" => %{
            "payID" => "jane@example.com",
            "payIDType" => "EMAIL"
          }
        },
        "paymentAgreementType" => "OTHER SERVICE",
        "description" => "Monthly subscription",
        "agreementDetails" => %{
          "variableAgreementDetails" => %{
            "startDate" => "2026-01-01",
            "endDate" => "2027-01-01",
            "maximumAmount" => "100.00",
            "frequency" => "MONTHLY"
          }
        }
      })
  """
  @spec create(Client.t(), map()) :: Request.response()
  def create(client, params) when is_map(params) do
    Request.post(client, "/paymentAgreement", json: %{"PaymentAgreement" => params})
  end

  @doc """
  Searches for payment agreements.

  The params map is automatically wrapped in the required `"PaymentAgreementSearch"` envelope.

  Note: `paymentAgreementId`, `contractId` and date fields cannot be included in the same request.

  ## Search fields

    * `paymentAgreementId` - ID of the payment agreement (1-40 chars)
    * `contractId` - Contract identifier
    * `fromDate` - Start of date range (UTC, ISO 8601)
    * `toDate` - End of date range (UTC, ISO 8601)

  ## Pagination

    * `nextPageId` - Pagination cursor from a previous search result
    * `numberOfRecords` - Number of records to retrieve (default 100)

  These pagination params are automatically extracted from the body and sent as query params.

  ## Examples

      {:ok, results} = Azupay.Client.PaymentAgreements.search(client, %{
        "paymentAgreementId" => "agr-123"
      })

      # With pagination
      {:ok, results} = Azupay.Client.PaymentAgreements.search(client, %{
        "paymentAgreementId" => "agr-123",
        "nextPageId" => "page-2",
        "numberOfRecords" => 50
      })
  """
  @spec search(Client.t(), map()) :: Request.response()
  def search(client, params) when is_map(params) do
    {query, body} = Request.extract_search_params(params)

    Request.post(client, "/paymentAgreement/search",
      json: %{"PaymentAgreementSearch" => body},
      params: query
    )
  end

  @doc """
  Amends an existing payment agreement.

  The params map is automatically wrapped in the required `"PaymentAgreementAmendment"` envelope.
  The `paymentAgreementId` should be included in the params.

  ## Examples

      {:ok, result} = Azupay.Client.PaymentAgreements.amend(client, %{
        "clientTransactionId" => "tx-amd-001",
        "paymentAgreementId" => "agreement-id",
        "agreementDetails" => %{
          "variableAgreementDetails" => %{
            "maximumAmount" => "150.00",
            "frequency" => "FORTNIGHTLY"
          }
        }
      })
  """
  @spec amend(Client.t(), map()) :: Request.response()
  def amend(client, params) when is_map(params) do
    Request.post(client, "/paymentAgreement/amendment",
      json: %{"PaymentAgreementAmendment" => params}
    )
  end

  @doc """
  Changes the status of a payment agreement.

  Valid statuses: `CANCELLED`, `SUSPENDED`, `ACTIVE`.

  ## Examples

      {:ok, result} = Azupay.Client.PaymentAgreements.change_status(client, "agreement-id", "SUSPENDED")
  """
  @spec change_status(Client.t(), String.t(), String.t()) :: Request.response()
  def change_status(client, id, status) when is_binary(status) do
    Request.post(client, "/paymentAgreement/changeStatus", params: [id: id, status: status])
  end
end
