defmodule Azupay.Webhook.PlugTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Azupay.Webhook.Token

  @signing_key "test-signing-key-at-least-32-chars!"
  @api_key "test-webhook-api-key"

  defmodule TestHandler do
    @behaviour Azupay.Webhook.Handler

    @impl true
    def handle_event(event_type, payload) do
      send(self(), {:webhook_received, event_type, payload})
      :ok
    end
  end

  defmodule ErrorHandler do
    @behaviour Azupay.Webhook.Handler

    @impl true
    def handle_event(_event_type, _payload) do
      {:error, :processing_failed}
    end
  end

  describe "API key auth" do
    @api_key_opts Azupay.Webhook.Plug.init(
                    auth: {:api_key, @api_key},
                    handler: TestHandler
                  )

    test "accepts valid API key and dispatches to handler" do
      payload = %{"entityType" => "PaymentRequest", "status" => "completed", "id" => "pr-123"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", @api_key)
        |> Azupay.Webhook.Plug.call(@api_key_opts)

      assert conn.status == 200
      assert_received {:webhook_received, "PaymentRequest", ^payload}
    end

    test "rejects invalid API key" do
      conn =
        conn(:post, "/", Jason.encode!(%{"entityType" => "Payment"}))
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "wrong-key")
        |> Azupay.Webhook.Plug.call(@api_key_opts)

      assert conn.status == 401
    end

    test "rejects missing Authorization header" do
      conn =
        conn(:post, "/", Jason.encode!(%{"entityType" => "Payment"}))
        |> put_req_header("content-type", "application/json")
        |> Azupay.Webhook.Plug.call(@api_key_opts)

      assert conn.status == 401
    end
  end

  describe "OAuth2 auth" do
    @oauth2_opts Azupay.Webhook.Plug.init(
                   auth: {:oauth2, signing_key: @signing_key},
                   handler: TestHandler
                 )

    test "accepts valid Bearer JWT and dispatches to handler" do
      {:ok, token, _ttl} = Token.generate(@signing_key)
      payload = %{"entityType" => "Payment", "status" => "settled", "id" => "pay-456"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "Bearer #{token}")
        |> Azupay.Webhook.Plug.call(@oauth2_opts)

      assert conn.status == 200
      assert_received {:webhook_received, "Payment", ^payload}
    end

    test "rejects expired Bearer JWT" do
      {:ok, token, _ttl} = Token.generate(@signing_key, ttl: -1)

      conn =
        conn(:post, "/", Jason.encode!(%{"entityType" => "Payment"}))
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "Bearer #{token}")
        |> Azupay.Webhook.Plug.call(@oauth2_opts)

      assert conn.status == 401
    end

    test "rejects JWT signed with wrong key" do
      {:ok, token, _ttl} = Token.generate("different-key-that-is-long-enough!")

      conn =
        conn(:post, "/", Jason.encode!(%{"entityType" => "Payment"}))
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "Bearer #{token}")
        |> Azupay.Webhook.Plug.call(@oauth2_opts)

      assert conn.status == 401
    end

    test "rejects non-Bearer Authorization header" do
      conn =
        conn(:post, "/", Jason.encode!(%{"entityType" => "Payment"}))
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "Basic abc123")
        |> Azupay.Webhook.Plug.call(@oauth2_opts)

      assert conn.status == 401
    end
  end

  describe "request handling" do
    @api_key_opts Azupay.Webhook.Plug.init(
                    auth: {:api_key, @api_key},
                    handler: TestHandler
                  )

    test "returns 405 for non-POST methods" do
      conn = conn(:get, "/") |> Azupay.Webhook.Plug.call(@api_key_opts)
      assert conn.status == 405
    end

    test "returns 400 for invalid JSON body" do
      conn =
        conn(:post, "/", "not valid json")
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", @api_key)
        |> Azupay.Webhook.Plug.call(@api_key_opts)

      assert conn.status == 400
    end

    test "uses 'unknown' when entityType is missing from payload" do
      payload = %{"status" => "completed", "id" => "pr-789"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", @api_key)
        |> Azupay.Webhook.Plug.call(@api_key_opts)

      assert conn.status == 200
      assert_received {:webhook_received, "unknown", ^payload}
    end

    test "supports custom event_type_key" do
      opts =
        Azupay.Webhook.Plug.init(
          auth: {:api_key, @api_key},
          handler: TestHandler,
          event_type_key: "type"
        )

      payload = %{"type" => "PaymentAgreement", "status" => "active"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", @api_key)
        |> Azupay.Webhook.Plug.call(opts)

      assert conn.status == 200
      assert_received {:webhook_received, "PaymentAgreement", ^payload}
    end
  end

  describe "both auth modes" do
    @both_opts Azupay.Webhook.Plug.init(
                 auth: [
                   {:api_key, @api_key},
                   {:oauth2, signing_key: @signing_key}
                 ],
                 handler: TestHandler
               )

    test "accepts valid API key when both modes configured" do
      payload = %{"entityType" => "PaymentRequest", "status" => "completed"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", @api_key)
        |> Azupay.Webhook.Plug.call(@both_opts)

      assert conn.status == 200
      assert_received {:webhook_received, "PaymentRequest", ^payload}
    end

    test "accepts valid Bearer JWT when both modes configured" do
      {:ok, token, _ttl} = Token.generate(@signing_key)
      payload = %{"entityType" => "Payment", "status" => "settled"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "Bearer #{token}")
        |> Azupay.Webhook.Plug.call(@both_opts)

      assert conn.status == 200
      assert_received {:webhook_received, "Payment", ^payload}
    end

    test "rejects invalid credentials when both modes configured" do
      conn =
        conn(:post, "/", Jason.encode!(%{"entityType" => "Payment"}))
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "wrong-key")
        |> Azupay.Webhook.Plug.call(@both_opts)

      assert conn.status == 401
    end
  end

  describe "handler errors" do
    test "returns 500 when handler returns error" do
      opts =
        Azupay.Webhook.Plug.init(
          auth: {:api_key, @api_key},
          handler: ErrorHandler
        )

      conn =
        conn(:post, "/", Jason.encode!(%{"entityType" => "Payment"}))
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", @api_key)
        |> Azupay.Webhook.Plug.call(opts)

      assert conn.status == 500
    end
  end
end
