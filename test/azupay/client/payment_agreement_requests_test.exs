defmodule Azupay.Client.PaymentAgreementRequestsTest do
  use ExUnit.Case, async: true

  alias Azupay.Client
  alias Azupay.Client.PaymentAgreementRequests

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
    test "sends POST to /paymentAgreementRequest with PaymentAgreementRequest envelope" do
      response_body = %{
        "PaymentAgreementRequest" => %{"clientTransactionId" => "tx-par-001"},
        "PaymentAgreementRequestStatus" => %{
          "paymentAgreementId" => "agr-123",
          "sessionUrl" => "https://checkout.azupay.com.au/session/123"
        }
      }

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/paymentAgreementRequest"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert %{
                 "PaymentAgreementRequest" => %{
                   "clientTransactionId" => "tx-par-001",
                   "agreementMaximumAmount" => "900.00"
                 }
               } = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(201, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               PaymentAgreementRequests.create(client, %{
                 "clientTransactionId" => "tx-par-001",
                 "agreementMaximumAmount" => "900.00"
               })
    end
  end
end
