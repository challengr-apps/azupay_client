defmodule Azupay.Client.PayIdDomains do
  @moduledoc """
  PayID domain management operations for the AzuPay API.

  Control the domains used for PayIDs. The first domain in the list is the
  default when no `payIDSuffix` is provided on a PaymentRequest.

  To get access to this API, submit a service desk request to Azupay.
  """

  alias Azupay.Client
  alias Azupay.Client.Request

  @doc """
  Lists configured PayID domains.

  ## Examples

      {:ok, domains} = Azupay.Client.PayIdDomains.list(client)
  """
  @spec list(Client.t()) :: Request.response()
  def list(client) do
    Request.get(client, "/config/payIdDomains")
  end

  @doc """
  Adds or updates PayID domains.

  Items not already on the list will be added; existing items will be updated.

  ## Examples

      {:ok, _} = Azupay.Client.PayIdDomains.upsert(client, [
        %{"domain" => "example.com.au", "merchantName" => "My Business"}
      ])
  """
  @spec upsert(Client.t(), list(map())) :: Request.response()
  def upsert(client, domains) when is_list(domains) do
    Request.post(client, "/config/payIdDomains", json: domains)
  end

  @doc """
  Deletes a PayID domain.

  Returns success even if the domain did not exist previously.

  ## Examples

      {:ok, _} = Azupay.Client.PayIdDomains.delete(client, "example.com.au")
  """
  @spec delete(Client.t(), String.t()) :: Request.response()
  def delete(client, domain) do
    Request.delete(client, "/config/payIdDomains/#{domain}")
  end
end
