defmodule Azupay.MockServer.Responses do
  @moduledoc """
  Standardized HTTP response helpers for the mock server.
  All responses match the AzuPay API format.
  """

  import Plug.Conn

  @doc """
  Sends a JSON response with the given status and data.
  """
  def json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end

  @doc """
  Sends a 201 Created response with payment request data.
  """
  def created(conn, data) do
    json(conn, 201, data)
  end

  @doc """
  Sends a 200 OK response with data.
  """
  def ok(conn, data) do
    json(conn, 200, data)
  end

  @doc """
  Sends a 204 No Content response for a successful deletion.
  """
  def deleted(conn) do
    conn
    |> send_resp(204, "")
  end

  @doc """
  Sends a search results response with records and optional pagination cursor.
  """
  def search_results(conn, records, next_page_id) do
    body = %{
      "records" => records,
      "recordCount" => length(records)
    }

    body =
      if next_page_id do
        Map.put(body, "nextPageId", next_page_id)
      else
        body
      end

    json(conn, 200, body)
  end

  @doc """
  Sends a 401 Unauthorized response.
  """
  def unauthorized(conn) do
    json(conn, 401, %{"error" => "unauthorized", "message" => "Invalid or missing API key"})
  end

  @doc """
  Sends a 404 Not Found response.
  """
  def not_found(conn, message \\ "Resource not found") do
    json(conn, 404, %{"error" => "not_found", "message" => message})
  end

  @doc """
  Sends a 422 Validation Error response.
  """
  def validation_error(conn, details) do
    json(conn, 422, %{
      "message" => "Validation failed",
      "details" => details
    })
  end

  @doc """
  Sends a generic error response.
  """
  def error(conn, status, code, message) do
    json(conn, status, %{"error" => code, "message" => message})
  end
end
