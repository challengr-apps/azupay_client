defmodule Azupay.Client.ApiKeysTest do
  use ExUnit.Case, async: true

  alias Azupay.Client
  alias Azupay.Client.ApiKeys

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
    test "sends POST to /apiKeys with params" do
      response_body = %{"keyId" => "key-123", "apiKey" => "secret"}

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/apiKeys"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert %{"clientId" => "sub-client-id"} = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(201, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               ApiKeys.create(client, %{"clientId" => "sub-client-id"})
    end
  end

  describe "list/1" do
    test "sends GET to /apiKeys" do
      response_body = [%{"keyId" => "key-123"}]

      plug = fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/apiKeys"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)
      assert {:ok, ^response_body} = ApiKeys.list(client)
    end
  end

  describe "get/2" do
    test "sends GET to /apiKeys/:keyId" do
      response_body = %{"keyId" => "key-123", "clientId" => "sub-client-id"}

      plug = fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/apiKeys/key-123"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)
      assert {:ok, ^response_body} = ApiKeys.get(client, "key-123")
    end
  end

  describe "update/3" do
    test "sends PATCH to /apiKeys/:keyId with params" do
      response_body = %{"keyId" => "key-123", "enabled" => false}

      plug = fn conn ->
        assert conn.method == "PATCH"
        assert conn.request_path == "/apiKeys/key-123"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert %{"enabled" => false} = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               ApiKeys.update(client, "key-123", %{"enabled" => false})
    end
  end
end
