defmodule Azupay.Client.BalanceAdjustmentsTest do
  use ExUnit.Case, async: true

  alias Azupay.Client
  alias Azupay.Client.BalanceAdjustments

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
    test "sends POST to /balanceAdjustment with BalanceAdjustment envelope" do
      response_body = %{
        "BalanceAdjustment" => %{"clientTransactionId" => "adj-001"},
        "BalanceAdjustmentStatus" => %{"balanceAdjustmentId" => "ba-123"}
      }

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/balanceAdjustment"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert %{
                 "BalanceAdjustment" => %{
                   "clientTransactionId" => "adj-001",
                   "adjustmentAmount" => "101.95",
                   "adjustmentType" => "CREDIT"
                 }
               } = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               BalanceAdjustments.create(client, %{
                 "clientTransactionId" => "adj-001",
                 "adjustmentAmount" => "101.95",
                 "adjustmentType" => "CREDIT",
                 "reason" => "Manual credit",
                 "clientId" => "my-client"
               })
    end
  end
end
