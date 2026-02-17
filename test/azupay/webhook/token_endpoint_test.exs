defmodule Azupay.Webhook.TokenEndpointTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Azupay.Webhook.TokenEndpoint
  alias Azupay.Webhook.Token

  @client_id "azupay-test-client"
  @client_secret "test-secret-value"
  @signing_key "test-signing-key-at-least-32-chars!"

  @opts TokenEndpoint.init(
          client_id: @client_id,
          client_secret: @client_secret,
          signing_key: @signing_key
        )

  describe "credentials in body" do
    test "issues a token for valid client_credentials grant" do
      body =
        URI.encode_query(%{
          "grant_type" => "client_credentials",
          "client_id" => @client_id,
          "client_secret" => @client_secret
        })

      conn =
        conn(:post, "/", body)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> TokenEndpoint.call(@opts)

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)
      assert response["token_type"] == "Bearer"
      assert is_binary(response["access_token"])
      assert response["expires_in"] == 3600

      # Verify the issued token is valid
      assert {:ok, _claims} = Token.verify(response["access_token"], @signing_key)
    end

    test "returns 401 for invalid client_secret in body" do
      body =
        URI.encode_query(%{
          "grant_type" => "client_credentials",
          "client_id" => @client_id,
          "client_secret" => "wrong-secret"
        })

      conn =
        conn(:post, "/", body)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> TokenEndpoint.call(@opts)

      assert conn.status == 401
      response = Jason.decode!(conn.resp_body)
      assert response["error"] == "invalid_client"
    end
  end

  describe "credentials in Authorization header (HTTP Basic)" do
    test "issues a token for valid Basic auth" do
      encoded = Base.encode64("#{@client_id}:#{@client_secret}")

      body = URI.encode_query(%{"grant_type" => "client_credentials"})

      conn =
        conn(:post, "/", body)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> put_req_header("authorization", "Basic #{encoded}")
        |> TokenEndpoint.call(@opts)

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)
      assert response["token_type"] == "Bearer"
      assert is_binary(response["access_token"])
    end

    test "returns 401 for invalid Basic auth" do
      encoded = Base.encode64("#{@client_id}:wrong-secret")

      body = URI.encode_query(%{"grant_type" => "client_credentials"})

      conn =
        conn(:post, "/", body)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> put_req_header("authorization", "Basic #{encoded}")
        |> TokenEndpoint.call(@opts)

      assert conn.status == 401
    end
  end

  describe "error handling" do
    test "returns 400 for unsupported grant_type" do
      body =
        URI.encode_query(%{
          "grant_type" => "authorization_code",
          "client_id" => @client_id,
          "client_secret" => @client_secret
        })

      conn =
        conn(:post, "/", body)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> TokenEndpoint.call(@opts)

      assert conn.status == 400
      response = Jason.decode!(conn.resp_body)
      assert response["error"] == "unsupported_grant_type"
    end

    test "returns 400 for missing grant_type" do
      body =
        URI.encode_query(%{
          "client_id" => @client_id,
          "client_secret" => @client_secret
        })

      conn =
        conn(:post, "/", body)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> TokenEndpoint.call(@opts)

      assert conn.status == 400
      response = Jason.decode!(conn.resp_body)
      assert response["error"] == "invalid_request"
    end

    test "returns 401 for missing credentials" do
      body = URI.encode_query(%{"grant_type" => "client_credentials"})

      conn =
        conn(:post, "/", body)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> TokenEndpoint.call(@opts)

      assert conn.status == 401
      response = Jason.decode!(conn.resp_body)
      assert response["error"] == "invalid_client"
    end

    test "returns 405 for non-POST methods" do
      conn = conn(:get, "/") |> TokenEndpoint.call(@opts)

      assert conn.status == 405
    end
  end

  describe "custom options" do
    test "respects custom token_ttl" do
      opts =
        TokenEndpoint.init(
          client_id: @client_id,
          client_secret: @client_secret,
          signing_key: @signing_key,
          token_ttl: 600
        )

      body =
        URI.encode_query(%{
          "grant_type" => "client_credentials",
          "client_id" => @client_id,
          "client_secret" => @client_secret
        })

      conn =
        conn(:post, "/", body)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> TokenEndpoint.call(opts)

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)
      assert response["expires_in"] == 600
    end
  end
end
