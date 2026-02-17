defmodule Azupay.Client.PaymentsTest do
  use ExUnit.Case, async: true

  alias Azupay.Client
  alias Azupay.Client.Payments

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
    test "sends POST to /payment with params wrapped in Payment envelope" do
      response_body = %{"paymentId" => "pay-123", "status" => "IN_PROGRESS"}

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/payment"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert %{
                 "Payment" => %{
                   "clientPaymentId" => "pay-001",
                   "payeeName" => "Jane Smith",
                   "payID" => "jane@example.com",
                   "payIDType" => "EMAIL",
                   "paymentAmount" => "100.00",
                   "paymentDescription" => "Invoice payment"
                 }
               } = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(201, Jason.encode!(response_body))
      end

      client = build_client(plug)

      params = %{
        "clientPaymentId" => "pay-001",
        "payeeName" => "Jane Smith",
        "payID" => "jane@example.com",
        "payIDType" => "EMAIL",
        "paymentAmount" => "100.00",
        "paymentDescription" => "Invoice payment"
      }

      assert {:ok, ^response_body} = Payments.create(client, params)
    end
  end

  describe "get/2" do
    test "sends GET to /payment with id query param" do
      response_body = %{"paymentId" => "pay-123", "status" => "COMPLETED"}

      plug = fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/payment"

        query = URI.decode_query(conn.query_string)
        assert query["id"] == "pay-123"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)
      assert {:ok, ^response_body} = Payments.get(client, "pay-123")
    end

    test "returns not_found for unknown payment" do
      plug = fn conn -> Plug.Conn.send_resp(conn, 404, "") end

      client = build_client(plug)
      assert {:error, :not_found} = Payments.get(client, "unknown")
    end
  end

  describe "search/2" do
    test "sends POST to /payment/search with PaymentSearch envelope" do
      response_body = %{"records" => [%{"paymentId" => "pay-123"}]}

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/payment/search"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert %{"PaymentSearch" => %{"clientPaymentId" => "pay-001"}} = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               Payments.search(client, %{"clientPaymentId" => "pay-001"})
    end
  end
end
