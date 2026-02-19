defmodule Azupay.Webhook.PlugTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  defmodule TestHandler do
    @behaviour Azupay.Webhook.Handler

    @impl true
    def handle_event(event_type, payload, context) do
      send(self(), {:webhook_received, event_type, payload, context})
      :ok
    end
  end

  defmodule UnauthorizedHandler do
    @behaviour Azupay.Webhook.Handler

    @impl true
    def handle_event(_event_type, _payload, _context) do
      {:error, :unauthorized}
    end
  end

  defmodule ErrorHandler do
    @behaviour Azupay.Webhook.Handler

    @impl true
    def handle_event(_event_type, _payload, _context) do
      {:error, :processing_failed}
    end
  end

  describe "event type inference" do
    @opts Azupay.Webhook.Plug.init(
            environment: :uat,
            handler: TestHandler
          )

    test "infers PaymentRequest from top-level key" do
      payload = %{
        "PaymentRequest" => %{"clientId" => "C1", "clientTransactionId" => "TX1"},
        "PaymentRequestStatus" => %{"paymentRequestId" => "pr-123", "status" => "COMPLETE"}
      }

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "Bearer secret-123")
        |> Azupay.Webhook.Plug.call(@opts)

      assert conn.status == 200

      assert_received {:webhook_received, "PaymentRequest", ^payload,
                       %{environment: :uat, authorization: "Bearer secret-123"}}
    end

    test "infers Payment from top-level key" do
      payload = %{
        "Payment" => %{"bsb" => "012306", "accountNumber" => "12345678"},
        "PaymentStatus" => %{"paymentId" => "pay-456", "status" => "SETTLED"}
      }

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Azupay.Webhook.Plug.call(@opts)

      assert conn.status == 200

      assert_received {:webhook_received, "Payment", ^payload,
                       %{environment: :uat, authorization: nil}}
    end

    test "infers PaymentAgreement from top-level key" do
      payload = %{
        "PaymentAgreement" => %{"agreementId" => "ag-789"},
        "PaymentAgreementStatus" => %{"status" => "ACTIVE"}
      }

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Azupay.Webhook.Plug.call(@opts)

      assert conn.status == 200
      assert_received {:webhook_received, "PaymentAgreement", ^payload, %{environment: :uat}}
    end

    test "infers PaymentAgreementAmendment from top-level key" do
      payload = %{
        "PaymentAgreementAmendment" => %{"amendmentId" => "am-101"},
        "PaymentAgreementAmendmentStatus" => %{"status" => "ACTIVE"}
      }

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Azupay.Webhook.Plug.call(@opts)

      assert conn.status == 200

      assert_received {:webhook_received, "PaymentAgreementAmendment", ^payload,
                       %{environment: :uat}}
    end

    test "infers PaymentInitiation from top-level key" do
      payload = %{
        "PaymentInitiation" => %{"initiationId" => "pi-202"},
        "PaymentInitiationStatus" => %{"status" => "SETTLED"}
      }

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Azupay.Webhook.Plug.call(@opts)

      assert conn.status == 200
      assert_received {:webhook_received, "PaymentInitiation", ^payload, %{environment: :uat}}
    end

    test "infers ClientEnabled from client key" do
      payload = %{"client" => %{"enabled" => true, "id" => "client-303"}}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Azupay.Webhook.Plug.call(@opts)

      assert conn.status == 200
      assert_received {:webhook_received, "ClientEnabled", ^payload, %{environment: :uat}}
    end

    test "returns 'unknown' when no known top-level key is present" do
      payload = %{"someUnknown" => "data"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Azupay.Webhook.Plug.call(@opts)

      assert conn.status == 200
      assert_received {:webhook_received, "unknown", ^payload, %{environment: :uat}}
    end
  end

  describe "successful dispatch" do
    @opts Azupay.Webhook.Plug.init(
            environment: :uat,
            handler: TestHandler
          )

    test "passes nil authorization when header is missing" do
      payload = %{"Payment" => %{}, "PaymentStatus" => %{"status" => "SETTLED"}}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Azupay.Webhook.Plug.call(@opts)

      assert conn.status == 200

      assert_received {:webhook_received, "Payment", ^payload,
                       %{environment: :uat, authorization: nil}}
    end

    test "passes the configured environment to the handler" do
      prod_opts =
        Azupay.Webhook.Plug.init(
          environment: :prod,
          handler: TestHandler
        )

      payload = %{"Payment" => %{}, "PaymentStatus" => %{"status" => "SETTLED"}}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Azupay.Webhook.Plug.call(prod_opts)

      assert conn.status == 200

      assert_received {:webhook_received, "Payment", ^payload,
                       %{environment: :prod, authorization: nil}}
    end
  end

  describe "handler errors" do
    test "returns 401 when handler returns {:error, :unauthorized}" do
      opts =
        Azupay.Webhook.Plug.init(
          environment: :uat,
          handler: UnauthorizedHandler
        )

      payload = %{"PaymentRequest" => %{}, "PaymentRequestStatus" => %{"status" => "COMPLETE"}}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Azupay.Webhook.Plug.call(opts)

      assert conn.status == 401
      assert Jason.decode!(conn.resp_body) == %{"error" => "unauthorized"}
    end

    test "returns 500 when handler returns {:error, reason}" do
      opts =
        Azupay.Webhook.Plug.init(
          environment: :uat,
          handler: ErrorHandler
        )

      payload = %{"Payment" => %{}, "PaymentStatus" => %{"status" => "SETTLED"}}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Azupay.Webhook.Plug.call(opts)

      assert conn.status == 500
    end
  end

  describe "pre-parsed body (Phoenix)" do
    @opts Azupay.Webhook.Plug.init(
            environment: :uat,
            handler: TestHandler
          )

    test "uses body_params when body has already been parsed by Plug.Parsers" do
      payload = %{
        "PaymentRequest" => %{"clientId" => "C1"},
        "PaymentRequestStatus" => %{"status" => "COMPLETE"}
      }

      # Simulate what Phoenix does: body_params is pre-populated, raw body is consumed
      conn =
        conn(:post, "/", "")
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "Bearer pre-parsed-token")
        |> Map.put(:body_params, payload)
        |> Azupay.Webhook.Plug.call(@opts)

      assert conn.status == 200

      assert_received {:webhook_received, "PaymentRequest", ^payload,
                       %{environment: :uat, authorization: "Bearer pre-parsed-token"}}
    end
  end

  describe "request validation" do
    @opts Azupay.Webhook.Plug.init(
            environment: :uat,
            handler: TestHandler
          )

    test "returns 405 for non-POST methods" do
      conn = conn(:get, "/") |> Azupay.Webhook.Plug.call(@opts)
      assert conn.status == 405
    end

    test "returns 400 for invalid JSON body" do
      conn =
        conn(:post, "/", "not valid json")
        |> put_req_header("content-type", "application/json")
        |> Azupay.Webhook.Plug.call(@opts)

      assert conn.status == 400
    end
  end
end
