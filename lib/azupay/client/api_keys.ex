defmodule Azupay.Client.ApiKeys do
  @moduledoc """
  API Key management operations for the AzuPay API.

  Create and manage API keys for sub-merchants.
  """

  alias Azupay.Client
  alias Azupay.Client.Request

  @doc """
  Creates API keys for a sub-merchant.

  ## Examples

      {:ok, key} = Azupay.Client.ApiKeys.create(client, %{
        "clientId" => "sub-client-id"
      })
  """
  @spec create(Client.t(), map()) :: Request.response()
  def create(client, params) when is_map(params) do
    Request.post(client, "/apiKeys", json: params)
  end

  @doc """
  Lists API keys for sub-merchants.

  ## Examples

      {:ok, keys} = Azupay.Client.ApiKeys.list(client)
  """
  @spec list(Client.t()) :: Request.response()
  def list(client) do
    Request.get(client, "/apiKeys")
  end

  @doc """
  Retrieves a specific API key by ID.

  ## Examples

      {:ok, key} = Azupay.Client.ApiKeys.get(client, "key-123")
  """
  @spec get(Client.t(), String.t()) :: Request.response()
  def get(client, key_id) do
    Request.get(client, "/apiKeys/#{key_id}")
  end

  @doc """
  Updates an API key.

  ## Examples

      {:ok, key} = Azupay.Client.ApiKeys.update(client, "key-123", %{
        "enabled" => false
      })
  """
  @spec update(Client.t(), String.t(), map()) :: Request.response()
  def update(client, key_id, params) when is_map(params) do
    Request.patch(client, "/apiKeys/#{key_id}", json: params)
  end
end
