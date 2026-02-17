defmodule Azupay.Client.BalancesTest do
  use ExUnit.Case, async: true

  alias Azupay.Client
  alias Azupay.Client.Balances

  defp build_client(plug) do
    Client.new(
      environment: :uat,
      api_key: "test_key",
      client_id: "test_client_id",
      base_url: "http://localhost",
      req_options: [plug: plug]
    )
  end

  describe "get/1" do
    test "sends GET to /balance" do
      response_body = %{"balance" => "1234.56"}

      plug = fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/balance"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)
      assert {:ok, ^response_body} = Balances.get(client)
    end
  end
end
