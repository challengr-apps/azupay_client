defmodule Azupay.Client.Balances do
  @moduledoc """
  Balance resource operations for the AzuPay API.
  """

  alias Azupay.Client
  alias Azupay.Client.Request

  @doc """
  Gets the current account balance in AUD.

  ## Examples

      {:ok, balance} = Azupay.Client.Balances.get(client)
  """
  @spec get(Client.t()) :: Request.response()
  def get(client) do
    Request.get(client, "/balance")
  end
end
