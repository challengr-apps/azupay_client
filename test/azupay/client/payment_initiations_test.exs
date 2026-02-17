defmodule Azupay.Client.PaymentInitiationsTest do
  use ExUnit.Case, async: true

  alias Azupay.Client
  alias Azupay.Client.PaymentInitiations

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
    test "sends POST to /paymentInitiation with PaymentInitiation envelope" do
      response_body = %{"paymentInitiationId" => "pi-123", "status" => "INITIATED"}

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/paymentInitiation"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert %{
                 "PaymentInitiation" => %{
                   "clientTransactionId" => "tx-pmt-001",
                   "paymentAmount" => "75.50"
                 }
               } = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(201, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               PaymentInitiations.create(client, %{
                 "clientTransactionId" => "tx-pmt-001",
                 "paymentAmount" => "75.50"
               })
    end
  end

  describe "get/2" do
    test "sends GET to /paymentInitiation with id query param" do
      response_body = %{"paymentInitiationId" => "pi-123", "status" => "COMPLETED"}

      plug = fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/paymentInitiation"

        query = URI.decode_query(conn.query_string)
        assert query["id"] == "pi-123"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)
      assert {:ok, ^response_body} = PaymentInitiations.get(client, "pi-123")
    end
  end

  describe "refund/3" do
    test "sends POST to /paymentInitiation/refund with id param for full refund" do
      response_body = %{"status" => "RETURN_IN_PROGRESS"}

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/paymentInitiation/refund"

        query = URI.decode_query(conn.query_string)
        assert query["id"] == "pi-123"
        refute Map.has_key?(query, "refundAmount")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)
      assert {:ok, ^response_body} = PaymentInitiations.refund(client, "pi-123")
    end

    test "includes refundAmount param for partial refund" do
      response_body = %{"status" => "RETURN_IN_PROGRESS"}

      plug = fn conn ->
        query = URI.decode_query(conn.query_string)
        assert query["id"] == "pi-123"
        assert query["refundAmount"] == "25.00"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               PaymentInitiations.refund(client, "pi-123", refund_amount: "25.00")
    end

    test "includes refundBatchId param" do
      response_body = %{"status" => "RETURN_IN_PROGRESS"}

      plug = fn conn ->
        query = URI.decode_query(conn.query_string)
        assert query["id"] == "pi-123"
        assert query["refundBatchId"] == "batch-1"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               PaymentInitiations.refund(client, "pi-123", refund_batch_id: "batch-1")
    end
  end

  describe "search/2" do
    test "sends POST to /paymentInitiation/search with PaymentInitiationSearch envelope" do
      response_body = %{"records" => [%{"paymentInitiationId" => "pi-123"}]}

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/paymentInitiation/search"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert %{"PaymentInitiationSearch" => %{"clientTransactionId" => "tx-001"}} = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               PaymentInitiations.search(client, %{"clientTransactionId" => "tx-001"})
    end
  end
end
