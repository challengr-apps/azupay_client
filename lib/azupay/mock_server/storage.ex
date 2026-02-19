if Code.ensure_loaded?(Ecto) do
  defmodule Azupay.MockServer.Storage do
    @moduledoc """
    Postgres storage for the mock server using the parent app's Ecto Repo.
    """

    import Ecto.Query

    alias Azupay.MockServer.Schema.PaymentRequest

    @doc """
    Returns the configured Repo module.
    """
    def repo do
      Application.get_env(:azupay, :mock_server, [])[:repo] ||
        raise "Azupay Mock Server requires :repo to be configured. " <>
                "Add `config :azupay, :mock_server, repo: MyApp.Repo` to your config."
    end

    # Payment request operations

    @doc """
    Inserts a new payment request.
    """
    def insert_payment_request(attrs) do
      %PaymentRequest{}
      |> PaymentRequest.create_changeset(attrs)
      |> repo().insert()
    end

    @doc """
    Gets a payment request by ID.
    """
    def get_payment_request(id) do
      case repo().get(PaymentRequest, id) do
        nil -> {:error, :not_found}
        payment_request -> {:ok, payment_request}
      end
    end

    @doc """
    Updates a payment request.
    """
    def update_payment_request(id, attrs) do
      case get_payment_request(id) do
        {:ok, payment_request} ->
          payment_request
          |> PaymentRequest.update_changeset(attrs)
          |> repo().update()

        {:error, :not_found} = error ->
          error
      end
    end

    @doc """
    Deletes a payment request by ID.
    """
    def delete_payment_request(id) do
      case get_payment_request(id) do
        {:ok, payment_request} ->
          repo().delete(payment_request)
          :ok

        {:error, :not_found} = error ->
          error
      end
    end

    @doc """
    Searches payment requests with optional filters and cursor pagination.

    ## Filters

      * `"clientTransactionId"` - Exact match on client transaction ID
      * `"payID"` - Exact match on PayID
      * `"fromDate"` - Filter by created date >= (ISO 8601)
      * `"toDate"` - Filter by created date <= (ISO 8601)

    ## Pagination

      * `"nextPageId"` - Cursor (payment request ID) to start after
      * `"numberOfRecords"` - Max records to return (default 100)
    """
    def search_payment_requests(filters, pagination \\ %{}) do
      number_of_records =
        case pagination do
          %{"numberOfRecords" => n} when is_integer(n) -> min(n, 1000)
          %{"numberOfRecords" => n} when is_binary(n) -> min(String.to_integer(n), 1000)
          _ -> 100
        end

      query =
        PaymentRequest
        |> maybe_filter_client_transaction_id(filters)
        |> maybe_filter_pay_id(filters)
        |> maybe_filter_from_date(filters)
        |> maybe_filter_to_date(filters)
        |> maybe_apply_cursor(pagination)
        |> order_by([pr], asc: pr.inserted_at, asc: pr.id)
        |> limit(^(number_of_records + 1))

      results = repo().all(query)

      {records, next_page_id} =
        if length(results) > number_of_records do
          records = Enum.take(results, number_of_records)
          last = List.last(records)
          {records, last.id}
        else
          {results, nil}
        end

      {records, next_page_id}
    end

    defp maybe_filter_client_transaction_id(query, %{"clientTransactionId" => id})
         when is_binary(id) and id != "" do
      where(query, [pr], pr.client_transaction_id == ^id)
    end

    defp maybe_filter_client_transaction_id(query, _), do: query

    defp maybe_filter_pay_id(query, %{"payID" => pay_id})
         when is_binary(pay_id) and pay_id != "" do
      where(query, [pr], pr.pay_id == ^pay_id)
    end

    defp maybe_filter_pay_id(query, _), do: query

    defp maybe_filter_from_date(query, %{"fromDate" => from_date}) when is_binary(from_date) do
      case DateTime.from_iso8601(from_date) do
        {:ok, dt, _} -> where(query, [pr], pr.inserted_at >= ^dt)
        _ -> query
      end
    end

    defp maybe_filter_from_date(query, _), do: query

    defp maybe_filter_to_date(query, %{"toDate" => to_date}) when is_binary(to_date) do
      case DateTime.from_iso8601(to_date) do
        {:ok, dt, _} -> where(query, [pr], pr.inserted_at <= ^dt)
        _ -> query
      end
    end

    defp maybe_filter_to_date(query, _), do: query

    defp maybe_apply_cursor(query, %{"nextPageId" => cursor_id})
         when is_binary(cursor_id) and cursor_id != "" do
      where(query, [pr], pr.id > ^cursor_id)
    end

    defp maybe_apply_cursor(query, _), do: query

    @doc """
    Gets a payment request by PayID.
    """
    def get_payment_request_by_pay_id(pay_id) do
      case repo().one(from(pr in PaymentRequest, where: pr.pay_id == ^pay_id)) do
        nil -> {:error, :not_found}
        payment_request -> {:ok, payment_request}
      end
    end

    @doc """
    Lists all payment requests.
    """
    def list_payment_requests do
      repo().all(from(pr in PaymentRequest, order_by: [desc: pr.inserted_at]))
    end

    @doc """
    Clears all mock payment request data.
    """
    def clear_all do
      repo().delete_all(PaymentRequest)
      :ok
    end
  end
end
