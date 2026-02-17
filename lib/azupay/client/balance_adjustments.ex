defmodule Azupay.Client.BalanceAdjustments do
  @moduledoc """
  Balance adjustment operations for the AzuPay API.

  Process adjustments to the ledger and account balance.
  """

  alias Azupay.Client
  alias Azupay.Client.Request

  @doc """
  Creates a balance adjustment.

  The params map is automatically wrapped in the required `"BalanceAdjustment"` envelope.

  ## Required fields

    * `clientTransactionId` - Unique ID for this adjustment (5-100 chars)
    * `adjustmentAmount` - Amount in AUD (e.g. "101.95")
    * `adjustmentType` - Either "CREDIT" or "DEBIT"
    * `reason` - Reason for the adjustment (5-50 chars)
    * `clientId` - Client identifier (5-50 chars)

  ## Examples

      {:ok, result} = Azupay.Client.BalanceAdjustments.create(client, %{
        "clientTransactionId" => "adj-001",
        "adjustmentAmount" => "101.95",
        "adjustmentType" => "CREDIT",
        "reason" => "Manual credit adjustment",
        "clientId" => "my-client-id"
      })
  """
  @spec create(Client.t(), map()) :: Request.response()
  def create(client, params) when is_map(params) do
    Request.post(client, "/balanceAdjustment", json: %{"BalanceAdjustment" => params})
  end
end
