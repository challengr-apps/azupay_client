defmodule Azupay.MockServer.State do
  @moduledoc """
  Business logic layer for the mock server.
  Handles payment request creation with proper structure and delegates to Storage.
  """

  alias Azupay.MockServer.Storage
  alias Azupay.MockServer.Schema.PaymentRequest
  alias Azupay.MockServer.Webhook

  @doc """
  Creates a new payment request from API params.
  Generates ID, PayID, and checkout URL automatically.
  """
  def create_payment_request(params) do
    id = Ecto.UUID.generate()

    pay_id =
      params["payID"] ||
        "#{Ecto.UUID.generate()}@#{params["payIDSuffix"] || "mock.azupay.com.au"}"

    checkout_url = build_checkout_url(id)

    attrs = %{
      id: id,
      client_id: params["clientId"],
      client_transaction_id: params["clientTransactionId"],
      payment_description: params["paymentDescription"],
      pay_id: pay_id,
      payment_amount: params["paymentAmount"],
      status: "WAITING",
      multi_payment: params["multiPayment"] || false,
      checkout_url: checkout_url,
      payment_expiry_datetime: params["paymentExpiryDatetime"],
      metadata: params["metaData"] || %{},
      payment_notification: params["paymentNotification"]
    }

    case Storage.insert_payment_request(attrs) do
      {:ok, payment_request} -> {:ok, PaymentRequest.to_api_response(payment_request)}
      {:error, changeset} -> {:error, format_changeset_errors(changeset)}
    end
  end

  @doc """
  Gets a payment request by ID and returns it in API format.
  """
  def get_payment_request(id) do
    case Storage.get_payment_request(id) do
      {:ok, payment_request} -> {:ok, PaymentRequest.to_api_response(payment_request)}
      {:error, :not_found} = error -> error
    end
  end

  @doc """
  Deletes a payment request by ID.
  """
  def delete_payment_request(id) do
    Storage.delete_payment_request(id)
  end

  @doc """
  Updates a payment request's status.
  """
  def update_payment_request(id, attrs) do
    case Storage.update_payment_request(id, attrs) do
      {:ok, payment_request} -> {:ok, PaymentRequest.to_api_response(payment_request)}
      {:error, :not_found} = error -> error
      {:error, changeset} -> {:error, format_changeset_errors(changeset)}
    end
  end

  @doc """
  Searches payment requests with filters and pagination.
  Returns `{records, next_page_id}`.
  """
  def search_payment_requests(filters, pagination \\ %{}) do
    {records, next_page_id} = Storage.search_payment_requests(filters, pagination)
    api_records = Enum.map(records, &PaymentRequest.to_api_response/1)
    {api_records, next_page_id}
  end

  @doc """
  Gets a payment request by PayID and returns it in API format.
  """
  def get_payment_request_by_pay_id(pay_id) do
    case Storage.get_payment_request_by_pay_id(pay_id) do
      {:ok, payment_request} -> {:ok, PaymentRequest.to_api_response(payment_request)}
      {:error, :not_found} = error -> error
    end
  end

  @doc """
  Simulates a payment being received for a payment request.
  Transitions status from WAITING to PAID.
  """
  def simulate_payment(id) do
    case Storage.get_payment_request(id) do
      {:ok, %{status: "WAITING"} = pr} ->
        case update_payment_request(id, %{status: "COMPLETE"}) do
          {:ok, api_response} = result ->
            Webhook.maybe_deliver(pr, api_response)
            result

          error ->
            error
        end

      {:ok, %{status: status}} ->
        {:error, {:invalid_state, "Payment request in #{status} state cannot be paid"}}

      {:error, :not_found} = error ->
        error
    end
  end

  @doc """
  Resets all mock data.
  """
  def reset do
    Storage.clear_all()
  end

  @doc """
  Returns all payment requests for debugging.
  """
  def get_state do
    Storage.list_payment_requests()
    |> Enum.map(&PaymentRequest.to_api_response/1)
  end

  defp build_checkout_url(id) do
    mock_config = Application.get_env(:azupay, :mock_server, [])
    base_url = mock_config[:base_url] || "http://localhost:#{mock_config[:port] || 4502}"
    "#{base_url}/checkout/#{id}"
  end

  defp format_changeset_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
