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
end
