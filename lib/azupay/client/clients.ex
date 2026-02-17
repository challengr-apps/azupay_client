defmodule Azupay.Client.Clients do
  @moduledoc """
  Sub-client management operations for the AzuPay API.

  Create and manage sub-clients (child accounts of your master client).
  This API is only available to some Azupay customers.
  """

  alias Azupay.Client
  alias Azupay.Client.Request

  @doc """
  Creates or replaces a sub-client.

  The params map is automatically wrapped in the required `"client"` envelope.
  Reusing the same `clientTransactionId` will replace an existing client.

  ## Examples

      {:ok, sub_client} = Azupay.Client.Clients.create(client, %{
        "clientTransactionId" => "sub-001",
        "legalName" => "Sub Business Pty Ltd",
        "abn" => "12345678901",
        "defaultPaymentExpiryDuration" => 60,
        "payIDDomains" => [%{"domain" => "example.com.au"}],
        "settlementAccountFullLegalName" => "Sub Business Pty Ltd",
        "kyc" => %{}
      })
  """
  @spec create(Client.t(), map()) :: Request.response()
  def create(client, params) when is_map(params) do
    Request.post(client, "/clients", json: %{"client" => params})
  end

  @doc """
  Disables a sub-client.

  ## Examples

      {:ok, _} = Azupay.Client.Clients.disable(client, "sub-client-id")
  """
  @spec disable(Client.t(), String.t()) :: Request.response()
  def disable(client, sub_client_id) do
    Request.put(client, "/clients",
      json: %{"client" => %{"id" => sub_client_id, "enabled" => false}}
    )
  end

  @doc """
  Sets the low balance alert threshold for a sub-client.

  ## Examples

      {:ok, _} = Azupay.Client.Clients.set_low_balance_threshold(client, "sub-client-id", "500.00")
  """
  @spec set_low_balance_threshold(Client.t(), String.t(), String.t()) :: Request.response()
  def set_low_balance_threshold(client, client_id, threshold) do
    Request.put(client, "/clients/#{client_id}/lowBalanceAlert/threshold",
      json: %{"threshold" => threshold}
    )
  end

  @doc """
  Sets the email addresses for low balance alerts.

  ## Examples

      {:ok, _} = Azupay.Client.Clients.set_alert_emails(client, "sub-client-id", ["alerts@example.com"])
  """
  @spec set_alert_emails(Client.t(), String.t(), list(String.t())) :: Request.response()
  def set_alert_emails(client, client_id, email_addresses) when is_list(email_addresses) do
    Request.put(client, "/clients/#{client_id}/lowBalanceAlert/emailAddresses",
      json: %{"emailAddresses" => email_addresses}
    )
  end
end
