defmodule Azupay.Client.PayIdDomainsTest do
  use ExUnit.Case, async: true

  alias Azupay.Client
  alias Azupay.Client.PayIdDomains

  defp build_client(plug) do
    Client.new(
      environment: :uat,
      api_key: "test_key",
      client_id: "test_client_id",
      base_url: "http://localhost",
      req_options: [plug: plug]
    )
  end

  describe "list/1" do
    test "sends GET to /config/payIdDomains" do
      response_body = [%{"domain" => "example.com.au", "merchantName" => "My Business"}]

      plug = fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/config/payIdDomains"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)
      assert {:ok, ^response_body} = PayIdDomains.list(client)
    end
  end

  describe "upsert/2" do
    test "sends POST to /config/payIdDomains with domain list" do
      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/config/payIdDomains"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert [%{"domain" => "example.com.au", "merchantName" => "My Business"}] = decoded

        Plug.Conn.send_resp(conn, 202, "")
      end

      client = build_client(plug)

      assert {:ok, _} =
               PayIdDomains.upsert(client, [
                 %{"domain" => "example.com.au", "merchantName" => "My Business"}
               ])
    end
  end

  describe "delete/2" do
    test "sends DELETE to /config/payIdDomains/:domain" do
      plug = fn conn ->
        assert conn.method == "DELETE"
        assert conn.request_path == "/config/payIdDomains/example.com.au"

        Plug.Conn.send_resp(conn, 204, "")
      end

      client = build_client(plug)
      assert {:ok, _} = PayIdDomains.delete(client, "example.com.au")
    end
  end
end
