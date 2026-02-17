defmodule Azupay.Client.PaymentRequestsTest do
  use ExUnit.Case, async: true

  alias Azupay.Client
  alias Azupay.Client.PaymentRequests

  defp build_client(plug) do
    Client.new(
      environment: :uat,
      api_key: "test_key",
      client_id: "test_client_id",
      base_url: "http://localhost",
      req_options: [plug: plug]
    )
  end

  describe "create/2" do
    test "sends POST to /paymentRequest with params wrapped in PaymentRequest envelope" do
      response_body = %{
        "paymentRequestId" => "pr-123",
        "status" => "WAITING",
        "createdDateTime" => "2026-02-16T10:00:00+11:00",
        "checkoutUrl" => "https://checkout.azupay.com.au/pr-123"
      }

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/paymentRequest"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert %{"PaymentRequest" => %{"clientId" => "test_client_id"}} = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(201, Jason.encode!(response_body))
      end

      client = build_client(plug)

      params = %{
        "clientTransactionId" => "txn-001",
        "paymentDescription" => "Test payment description"
      }

      assert {:ok, ^response_body} = PaymentRequests.create(client, params)
    end

    test "returns validation error for invalid params" do
      error_body = %{
        "message" => "Validation failed",
        "details" => %{
          "failureCode" => "VALIDATION_ERROR",
          "failureReason" => "clientId is required"
        }
      }

      plug = fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(422, Jason.encode!(error_body))
      end

      client = build_client(plug)
      assert {:error, {:validation_error, ^error_body}} = PaymentRequests.create(client, %{})
    end

    test "returns unauthorized for invalid API key" do
      plug = fn conn -> Plug.Conn.send_resp(conn, 401, "") end

      client = build_client(plug)
      assert {:error, :unauthorized} = PaymentRequests.create(client, %{})
    end
  end

  describe "get/2" do
    test "sends GET to /paymentRequest with id query param" do
      response_body = %{"paymentRequestId" => "pr-123", "status" => "WAITING"}

      plug = fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/paymentRequest"

        query = URI.decode_query(conn.query_string)
        assert query["id"] == "pr-123"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)
      assert {:ok, ^response_body} = PaymentRequests.get(client, "pr-123")
    end

    test "returns not_found for unknown payment request" do
      plug = fn conn -> Plug.Conn.send_resp(conn, 404, "") end

      client = build_client(plug)
      assert {:error, :not_found} = PaymentRequests.get(client, "unknown")
    end
  end

  describe "delete/2" do
    test "sends DELETE to /paymentRequest with id query param" do
      plug = fn conn ->
        assert conn.method == "DELETE"
        assert conn.request_path == "/paymentRequest"

        query = URI.decode_query(conn.query_string)
        assert query["id"] == "pr-123"

        Plug.Conn.send_resp(conn, 204, "")
      end

      client = build_client(plug)
      assert {:ok, _} = PaymentRequests.delete(client, "pr-123")
    end
  end

  describe "refund/3" do
    test "sends POST to /paymentRequest/refund with id param for full refund" do
      response_body = %{"status" => "RETURN_IN_PROGRESS"}

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/paymentRequest/refund"

        query = URI.decode_query(conn.query_string)
        assert query["id"] == "pr-123"
        refute Map.has_key?(query, "refundAmount")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)
      assert {:ok, ^response_body} = PaymentRequests.refund(client, "pr-123")
    end

    test "includes refundAmount param for partial refund" do
      response_body = %{"status" => "RETURN_IN_PROGRESS"}

      plug = fn conn ->
        query = URI.decode_query(conn.query_string)
        assert query["id"] == "pr-123"
        assert query["refundAmount"] == "5.00"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               PaymentRequests.refund(client, "pr-123", refund_amount: "5.00")
    end
  end

  describe "search/2" do
    test "sends POST to /paymentRequest/search with PaymentRequestSearch envelope" do
      response_body = %{"records" => [%{"paymentRequestId" => "pr-123"}]}

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/paymentRequest/search"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert %{"PaymentRequestSearch" => %{"clientTransactionId" => "txn-001"}} = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               PaymentRequests.search(client, %{"clientTransactionId" => "txn-001"})
    end

    test "extracts pagination params to query string" do
      response_body = %{"records" => [], "nextPageId" => "page-2"}

      plug = fn conn ->
        query = URI.decode_query(conn.query_string)
        assert query["nextPageId"] == "page-1"
        assert query["numberOfRecords"] == "50"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        search_body = decoded["PaymentRequestSearch"]
        refute Map.has_key?(search_body, "nextPageId")
        refute Map.has_key?(search_body, "numberOfRecords")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               PaymentRequests.search(client, %{
                 "clientTransactionId" => "txn-001",
                 "nextPageId" => "page-1",
                 "numberOfRecords" => 50
               })
    end
  end
end
