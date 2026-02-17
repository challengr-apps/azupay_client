defmodule Azupay.Client.PaymentAgreementsTest do
  use ExUnit.Case, async: true

  alias Azupay.Client
  alias Azupay.Client.PaymentAgreements

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
    test "sends POST to /paymentAgreement with PaymentAgreement envelope" do
      response_body = %{"paymentAgreementId" => "agr-123", "status" => "CREATED"}

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/paymentAgreement"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert %{"PaymentAgreement" => %{"clientTransactionId" => "tx-001"}} = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(201, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               PaymentAgreements.create(client, %{"clientTransactionId" => "tx-001"})
    end
  end

  describe "search/2" do
    test "sends POST to /paymentAgreement/search with PaymentAgreementSearch envelope" do
      response_body = %{"records" => [%{"paymentAgreementId" => "agr-123"}]}

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/paymentAgreement/search"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert %{"PaymentAgreementSearch" => %{"paymentAgreementId" => "agr-123"}} = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               PaymentAgreements.search(client, %{"paymentAgreementId" => "agr-123"})
    end
  end

  describe "amend/2" do
    test "sends POST to /paymentAgreement/amendment with PaymentAgreementAmendment envelope" do
      response_body = %{"status" => "AMENDMENT_PENDING"}

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/paymentAgreement/amendment"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert %{
                 "PaymentAgreementAmendment" => %{
                   "clientTransactionId" => "tx-amd-001",
                   "paymentAgreementId" => "agr-123"
                 }
               } = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(201, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               PaymentAgreements.amend(client, %{
                 "clientTransactionId" => "tx-amd-001",
                 "paymentAgreementId" => "agr-123"
               })
    end
  end

  describe "change_status/3" do
    test "sends POST to /paymentAgreement/changeStatus with query params" do
      response_body = %{"status" => "SUSPENDED"}

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/paymentAgreement/changeStatus"

        query = URI.decode_query(conn.query_string)
        assert query["id"] == "agr-123"
        assert query["status"] == "SUSPENDED"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               PaymentAgreements.change_status(client, "agr-123", "SUSPENDED")
    end
  end
end
