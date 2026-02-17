defmodule Azupay.Client.Accounts do
  @moduledoc """
  Account enquiry operations for the AzuPay API.

  Provides BSB reachability checks, PayID status lookups, and
  Confirmation of Payee (CoP) account verification.
  """

  alias Azupay.Client
  alias Azupay.Client.Request

  @doc """
  Checks a BSB for NPP and PayTo reachability.

  ## Examples

      {:ok, status} = Azupay.Client.Accounts.check_bsb(client, %{"bsb" => "012306"})
      # => %{"AccountStatus" => %{"nppReachable" => true, "paytoReachable" => true, ...}}
  """
  @spec check_bsb(Client.t(), map()) :: Request.response()
  def check_bsb(client, params) when is_map(params) do
    Request.post(client, "/accountEnquiry", json: params)
  end

  @doc """
  Checks the status of a PayID.

  ## Parameters

    * `payID` - The PayID to check (required)
    * `payIDType` - Type: PHONE, EMAIL, ABN, or ORG (required)
    * `bsb` - BSB to validate (optional)
    * `accountNumber` - Account number to validate (optional)
    * `accountName` - Account name to check against PayID legal name (optional)

  ## Examples

      {:ok, status} = Azupay.Client.Accounts.check_payid(client, %{
        "payID" => "jane@example.com",
        "payIDType" => "EMAIL"
      })
  """
  @spec check_payid(Client.t(), map()) :: Request.response()
  def check_payid(client, params) when is_map(params) do
    Request.post(client, "/payIDEnquiry", json: params)
  end

  @doc """
  Confirms BSB/account number and payee name via Confirmation of Payee (CoP).

  ## Required parameters

    * `accountCheckId` - Tracking identifier (5-100 chars)
    * `bsb` - BSB code (6 digits)
    * `accountNumber` - Account number (4-12 digits)
    * `accountName` - Account holder's legal name (1-140 chars)
    * `purposeCode` - Lookup purpose: PYMT, PAYE, MAND, PIRQ, or VADR
    * `additionalDetails` - Object with `endUserId` and `endUserSessionId`

  ## Examples

      {:ok, result} = Azupay.Client.Accounts.check_account(client, %{
        "accountCheckId" => "check-001",
        "bsb" => "012306",
        "accountNumber" => "123456789",
        "accountName" => "Jane Smith",
        "purposeCode" => "PYMT",
        "additionalDetails" => %{
          "endUserId" => "user-1",
          "endUserSessionId" => "session-1"
        }
      })
  """
  @spec check_account(Client.t(), map()) :: Request.response()
  def check_account(client, params) when is_map(params) do
    Request.post(client, "/accountCheck", json: params)
  end
end
