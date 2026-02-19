defmodule Azupay.MockServer.WebhookTest do
  use ExUnit.Case, async: false

  alias Azupay.MockServer.Webhook

  describe "maybe_deliver/2" do
    test "returns :ok when payment_notification is nil" do
      assert :ok = Webhook.maybe_deliver(%{payment_notification: nil}, %{})
    end

    test "returns :ok when payment_notification URL is empty" do
      pr = %{payment_notification: %{"paymentNotificationEndpointUrl" => ""}}
      assert :ok = Webhook.maybe_deliver(pr, %{})
    end

    test "returns :ok when payment_notification URL is missing" do
      pr = %{payment_notification: %{}}
      assert :ok = Webhook.maybe_deliver(pr, %{})
    end

    test "delivers webhook POST to configured URL with correct payload and auth header" do
      test_pid = self()

      plug = fn conn, _opts ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        [auth] = Plug.Conn.get_req_header(conn, "authorization")
        send(test_pid, {:webhook_received, Jason.decode!(body), auth})
        Plug.Conn.send_resp(conn, 200, "OK")
      end

      {:ok, server} = Bandit.start_link(plug: plug, port: 0, scheme: :http)
      {:ok, {_, port}} = ThousandIsland.listener_info(server)

      pr = %{
        payment_notification: %{
          "paymentNotificationEndpointUrl" => "http://localhost:#{port}/callback",
          "paymentNotificationAuthorizationHeaderValue" => "Bearer test-secret-123"
        }
      }

      api_response = %{
        "PaymentRequest" => %{
          "payID" => "test@mock.azupay.com.au",
          "clientId" => "CLIENT1",
          "clientTransactionId" => "TX123",
          "paymentDescription" => "Test payment",
          "paymentAmount" => 42.50,
          "checkoutUrl" => "http://localhost:4502/checkout/abc-123"
        },
        "PaymentRequestStatus" => %{
          "paymentRequestId" => "abc-123",
          "status" => "COMPLETE",
          "createdDateTime" => "2026-02-19T00:00:00Z"
        }
      }

      assert :ok = Webhook.maybe_deliver(pr, api_response)

      assert_receive {:webhook_received, body, auth}, 5_000

      # Verify auth header
      assert auth == "Bearer test-secret-123"

      # Verify PaymentRequest fields are passed through
      assert body["PaymentRequest"]["clientTransactionId"] == "TX123"
      assert body["PaymentRequest"]["paymentAmount"] == 42.50
      assert body["PaymentRequest"]["payID"] == "test@mock.azupay.com.au"

      # Verify PaymentRequestStatus has original + enriched fields
      status = body["PaymentRequestStatus"]
      assert status["paymentRequestId"] == "abc-123"
      assert status["status"] == "COMPLETE"
      assert status["createdDateTime"] == "2026-02-19T00:00:00Z"
      assert status["completedDatetime"]
      assert status["amountReceived"] == 42.50
      assert status["settledBy"] == "PayID"

      Supervisor.stop(server)
    end

    test "delivers webhook without auth header when not configured" do
      test_pid = self()

      plug = fn conn, _opts ->
        {:ok, _body, conn} = Plug.Conn.read_body(conn)
        auth = Plug.Conn.get_req_header(conn, "authorization")
        send(test_pid, {:webhook_received, auth})
        Plug.Conn.send_resp(conn, 200, "OK")
      end

      {:ok, server} = Bandit.start_link(plug: plug, port: 0, scheme: :http)
      {:ok, {_, port}} = ThousandIsland.listener_info(server)

      pr = %{
        payment_notification: %{
          "paymentNotificationEndpointUrl" => "http://localhost:#{port}/callback"
        }
      }

      api_response = %{
        "PaymentRequest" => %{},
        "PaymentRequestStatus" => %{"status" => "COMPLETE"}
      }

      assert :ok = Webhook.maybe_deliver(pr, api_response)

      assert_receive {:webhook_received, []}, 5_000

      Supervisor.stop(server)
    end
  end
end
