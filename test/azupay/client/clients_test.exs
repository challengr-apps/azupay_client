defmodule Azupay.Client.ClientsTest do
  use ExUnit.Case, async: true

  alias Azupay.Client
  alias Azupay.Client.Clients

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
    test "sends POST to /clients with params wrapped in client envelope" do
      response_body = %{"client" => %{"id" => "sub-123", "legalName" => "Sub Business"}}

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/clients"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert %{
                 "client" => %{
                   "legalName" => "Sub Business",
                   "abn" => "12345678901"
                 }
               } = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(201, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               Clients.create(client, %{
                 "legalName" => "Sub Business",
                 "abn" => "12345678901"
               })
    end
  end

  describe "disable/2" do
    test "sends PUT to /clients with DisableClient body" do
      response_body = %{"client" => %{"id" => "sub-123", "enabled" => false}}

      plug = fn conn ->
        assert conn.method == "PUT"
        assert conn.request_path == "/clients"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert %{"client" => %{"id" => "sub-123", "enabled" => false}} = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(202, Jason.encode!(response_body))
      end

      client = build_client(plug)
      assert {:ok, ^response_body} = Clients.disable(client, "sub-123")
    end
  end

  describe "set_low_balance_threshold/3" do
    test "sends PUT to /clients/:clientId/lowBalanceAlert/threshold" do
      response_body = %{"threshold" => "500.00"}

      plug = fn conn ->
        assert conn.method == "PUT"
        assert conn.request_path == "/clients/sub-123/lowBalanceAlert/threshold"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert %{"threshold" => "500.00"} = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               Clients.set_low_balance_threshold(client, "sub-123", "500.00")
    end
  end

  describe "set_alert_emails/3" do
    test "sends PUT to /clients/:clientId/lowBalanceAlert/emailAddresses" do
      response_body = %{"emailAddresses" => ["alerts@example.com"]}

      plug = fn conn ->
        assert conn.method == "PUT"
        assert conn.request_path == "/clients/sub-123/lowBalanceAlert/emailAddresses"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert %{"emailAddresses" => ["alerts@example.com"]} = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               Clients.set_alert_emails(client, "sub-123", ["alerts@example.com"])
    end
  end
end
