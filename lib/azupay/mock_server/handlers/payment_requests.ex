defmodule Azupay.MockServer.Handlers.PaymentRequests do
  @moduledoc """
  Handles all payment request endpoints for the mock server.
  """

  alias Azupay.MockServer.State
  alias Azupay.MockServer.Responses

  @doc """
  Handles POST /v1/paymentRequest - Create a new payment request.
  """
  def create(conn) do
    with_auth(conn, fn ->
      case conn.body_params do
        %{"PaymentRequest" => params} ->
          case validate_create_params(params) do
            :ok ->
              case State.create_payment_request(params) do
                {:ok, payment_request} ->
                  Responses.created(conn, payment_request)

                {:error, errors} ->
                  Responses.validation_error(conn, errors)
              end

            {:error, errors} ->
              Responses.validation_error(conn, errors)
          end

        _ ->
          Responses.validation_error(conn, %{
            "PaymentRequest" => "Request body must contain a PaymentRequest envelope"
          })
      end
    end)
  end

  @doc """
  Handles GET /v1/paymentRequest - Get a payment request by ID.
  """
  def get(conn) do
    with_auth(conn, fn ->
      case conn.query_params do
        %{"id" => id} ->
          case State.get_payment_request(id) do
            {:ok, payment_request} -> Responses.ok(conn, payment_request)
            {:error, :not_found} -> Responses.not_found(conn, "Payment request not found")
          end

        _ ->
          Responses.validation_error(conn, %{"id" => "query parameter is required"})
      end
    end)
  end

  @doc """
  Handles DELETE /v1/paymentRequest - Delete a payment request by ID.
  """
  def delete(conn) do
    with_auth(conn, fn ->
      case conn.query_params do
        %{"id" => id} ->
          case State.delete_payment_request(id) do
            :ok -> Responses.deleted(conn)
            {:error, :not_found} -> Responses.not_found(conn, "Payment request not found")
          end

        _ ->
          Responses.validation_error(conn, %{"id" => "query parameter is required"})
      end
    end)
  end

  @doc """
  Handles POST /v1/paymentRequest/refund - Refund a payment request.
  """
  def refund(conn) do
    with_auth(conn, fn ->
      case conn.query_params do
        %{"id" => id} ->
          case State.update_payment_request(id, %{status: "RETURN_IN_PROGRESS"}) do
            {:ok, payment_request} ->
              Responses.ok(conn, payment_request)

            {:error, :not_found} ->
              Responses.not_found(conn, "Payment request not found")
          end

        _ ->
          Responses.validation_error(conn, %{"id" => "query parameter is required"})
      end
    end)
  end

  @doc """
  Handles POST /v1/paymentRequest/search - Search payment requests.
  """
  def search(conn) do
    with_auth(conn, fn ->
      case conn.body_params do
        %{"PaymentRequestSearch" => filters} ->
          pagination = conn.query_params
          {records, next_page_id} = State.search_payment_requests(filters, pagination)
          Responses.search_results(conn, records, next_page_id)

        _ ->
          Responses.validation_error(conn, %{
            "PaymentRequestSearch" => "Request body must contain a PaymentRequestSearch envelope"
          })
      end
    end)
  end

  # Private helpers

  defp with_auth(conn, fun) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      [api_key] when api_key != "" -> fun.()
      _ -> Responses.unauthorized(conn)
    end
  end

  defp validate_create_params(params) do
    errors = %{}

    errors =
      if is_nil(params["clientTransactionId"]) or params["clientTransactionId"] == "" do
        Map.put(errors, "clientTransactionId", "is required")
      else
        errors
      end

    errors =
      if is_nil(params["paymentDescription"]) or params["paymentDescription"] == "" do
        Map.put(errors, "paymentDescription", "is required")
      else
        errors
      end

    if map_size(errors) == 0, do: :ok, else: {:error, errors}
  end
end
