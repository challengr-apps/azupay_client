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

  describe "successful dispatch" do
    @opts Azupay.Webhook.Plug.init(
            environment: :uat,
            handler: TestHandler
          )

    test "dispatches event with environment and authorization in context" do
      payload = %{"entityType" => "PaymentRequest", "status" => "completed", "id" => "pr-123"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "my-secret-key")
        |> Azupay.Webhook.Plug.call(@opts)

      assert conn.status == 200

      assert_received {:webhook_received, "PaymentRequest", ^payload,
                       %{environment: :uat, authorization: "my-secret-key"}}
    end

    test "passes nil authorization when header is missing" do
      payload = %{"entityType" => "Payment", "status" => "settled"}

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

      payload = %{"entityType" => "Payment", "status" => "settled"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Azupay.Webhook.Plug.call(prod_opts)

      assert conn.status == 200

      assert_received {:webhook_received, "Payment", ^payload,
                       %{environment: :prod, authorization: nil}}
    end

    test "uses 'unknown' when entityType is missing from payload" do
      payload = %{"status" => "completed", "id" => "pr-789"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Azupay.Webhook.Plug.call(@opts)

      assert conn.status == 200
      assert_received {:webhook_received, "unknown", ^payload, %{environment: :uat}}
    end

    test "supports custom event_type_key" do
      opts =
        Azupay.Webhook.Plug.init(
          environment: :uat,
          handler: TestHandler,
          event_type_key: "type"
        )

      payload = %{"type" => "PaymentAgreement", "status" => "active"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Azupay.Webhook.Plug.call(opts)

      assert conn.status == 200
      assert_received {:webhook_received, "PaymentAgreement", ^payload, %{environment: :uat}}
    end
  end

  describe "handler errors" do
    test "returns 401 when handler returns {:error, :unauthorized}" do
      opts =
        Azupay.Webhook.Plug.init(
          environment: :uat,
          handler: UnauthorizedHandler
        )

      conn =
        conn(:post, "/", Jason.encode!(%{"entityType" => "Payment"}))
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

      conn =
        conn(:post, "/", Jason.encode!(%{"entityType" => "Payment"}))
        |> put_req_header("content-type", "application/json")
        |> Azupay.Webhook.Plug.call(opts)

      assert conn.status == 500
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
