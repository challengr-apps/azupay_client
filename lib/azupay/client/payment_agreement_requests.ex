defmodule Azupay.Client.PaymentAgreementRequests do
  @moduledoc """
  Payment Agreement Request resource operations for the AzuPay API.

  Payment Agreement Requests initiate the payer approval flow for PayTo agreements.
  The response includes a `sessionUrl` to redirect the payer for approval.
  """

  alias Azupay.Client
  alias Azupay.Client.Request

  @doc """
  Creates a new payment agreement request.

  The params map is automatically wrapped in the required `"PaymentAgreementRequest"` envelope.

  ## Examples

      {:ok, result} = Azupay.Client.PaymentAgreementRequests.create(client, %{
        "clientTransactionId" => "tx-par-001",
        "agreementMaximumAmount" => "900.00"
      })
  """
  @spec create(Client.t(), map()) :: Request.response()
  def create(client, params) when is_map(params) do
    Request.post(client, "/paymentAgreementRequest", json: %{"PaymentAgreementRequest" => params})
  end
end
