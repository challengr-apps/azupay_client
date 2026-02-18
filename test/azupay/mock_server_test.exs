defmodule Azupay.MockServerTest do
  use ExUnit.Case

  alias Azupay.Client
  alias Azupay.MockServer

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Azupay.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Azupay.TestRepo, {:shared, self()})
    MockServer.reset()
    :ok
  end

  defp create_client do
    Client.new(environment: :uat)
  end

  describe "create payment request" do
    test "creates with valid params and returns expected response" do
      client = create_client()

      {:ok, result} =
        Client.PaymentRequests.create(client, %{
          "clientTransactionId" => "txn-001",
          "paymentDescription" => "Test payment description"
        })

      pr = result["PaymentRequest"]
      status = result["PaymentRequestStatus"]

      assert status["paymentRequestId"]
      assert status["status"] == "WAITING"
      assert status["createdDateTime"]
      assert pr["checkoutUrl"]
      assert pr["clientTransactionId"] == "txn-001"
      assert pr["paymentDescription"] == "Test payment description"
      assert pr["payID"]
    end

    test "creates with all optional fields" do
      client = create_client()

      {:ok, result} =
        Client.PaymentRequests.create(client, %{
          "clientTransactionId" => "txn-002",
          "paymentDescription" => "Full payment request",
          "payID" => "custom-payid@merchant.com.au",
          "paymentAmount" => 29.99,
          "multiPayment" => true,
          "paymentExpiryDatetime" => "2026-03-01T00:00:00+11:00",
          "metaData" => %{"orderId" => "order-123"}
        })

      pr = result["PaymentRequest"]
      status = result["PaymentRequestStatus"]

      assert status["paymentRequestId"]
      assert pr["payID"] == "custom-payid@merchant.com.au"
      assert pr["paymentAmount"] == 29.99
      assert pr["multiPayment"] == true
      assert pr["metaData"] == %{"orderId" => "order-123"}
    end

    test "returns validation error with missing required fields" do
      client = create_client()

      {:error, {:validation_error, body}} =
        Client.PaymentRequests.create(client, %{})

      assert body["details"]["clientTransactionId"]
      assert body["details"]["paymentDescription"]
    end

    test "returns 401 without API key" do
      client = Client.new(environment: :uat, api_key: "", base_url: "http://localhost:4502/v1")

      assert {:error, :unauthorized} =
               Client.PaymentRequests.create(client, %{
                 "clientTransactionId" => "txn-003",
                 "paymentDescription" => "Should fail"
               })
    end
  end

  describe "get payment request" do
    test "returns payment request by ID" do
      client = create_client()

      {:ok, created} =
        Client.PaymentRequests.create(client, %{
          "clientTransactionId" => "txn-get-001",
          "paymentDescription" => "Get test payment"
        })

      id = created["PaymentRequestStatus"]["paymentRequestId"]
      {:ok, result} = Client.PaymentRequests.get(client, id)

      assert result["PaymentRequestStatus"]["paymentRequestId"] == id
      assert result["PaymentRequestStatus"]["status"] == "WAITING"
      assert result["PaymentRequest"]["clientTransactionId"] == "txn-get-001"
    end

    test "returns 404 for unknown ID" do
      client = create_client()

      assert {:error, :not_found} = Client.PaymentRequests.get(client, "unknown-id")
    end
  end

  describe "delete payment request" do
    test "deletes a payment request" do
      client = create_client()

      {:ok, created} =
        Client.PaymentRequests.create(client, %{
          "clientTransactionId" => "txn-del-001",
          "paymentDescription" => "Delete test payment"
        })

      id = created["PaymentRequestStatus"]["paymentRequestId"]
      assert {:ok, _} = Client.PaymentRequests.delete(client, id)

      # Verify it's gone
      assert {:error, :not_found} = Client.PaymentRequests.get(client, id)
    end
  end

  describe "refund payment request" do
    test "full refund sets status to RETURN_IN_PROGRESS" do
      client = create_client()

      {:ok, created} =
        Client.PaymentRequests.create(client, %{
          "clientTransactionId" => "txn-refund-001",
          "paymentDescription" => "Refund test payment"
        })

      id = created["PaymentRequestStatus"]["paymentRequestId"]
      {:ok, result} = Client.PaymentRequests.refund(client, id)

      assert result["PaymentRequestStatus"]["status"] == "RETURN_IN_PROGRESS"
    end

    test "partial refund also sets status to RETURN_IN_PROGRESS" do
      client = create_client()

      {:ok, created} =
        Client.PaymentRequests.create(client, %{
          "clientTransactionId" => "txn-refund-002",
          "paymentDescription" => "Partial refund test",
          "paymentAmount" => 50.00
        })

      id = created["PaymentRequestStatus"]["paymentRequestId"]

      {:ok, result} =
        Client.PaymentRequests.refund(client, id, refund_amount: "25.00")

      assert result["PaymentRequestStatus"]["status"] == "RETURN_IN_PROGRESS"
    end
  end

  describe "search payment requests" do
    test "searches by clientTransactionId" do
      client = create_client()

      {:ok, _} =
        Client.PaymentRequests.create(client, %{
          "clientTransactionId" => "txn-search-001",
          "paymentDescription" => "Search test payment"
        })

      {:ok, _} =
        Client.PaymentRequests.create(client, %{
          "clientTransactionId" => "txn-search-002",
          "paymentDescription" => "Another payment"
        })

      {:ok, result} =
        Client.PaymentRequests.search(client, %{"clientTransactionId" => "txn-search-001"})

      assert length(result["records"]) == 1
      assert result["recordCount"] == 1

      record = hd(result["records"])
      assert record["PaymentRequest"]["clientTransactionId"] == "txn-search-001"
    end

    test "returns all records when no filters" do
      client = create_client()

      {:ok, _} =
        Client.PaymentRequests.create(client, %{
          "clientTransactionId" => "txn-all-001",
          "paymentDescription" => "First payment"
        })

      {:ok, _} =
        Client.PaymentRequests.create(client, %{
          "clientTransactionId" => "txn-all-002",
          "paymentDescription" => "Second payment"
        })

      {:ok, result} = Client.PaymentRequests.search(client, %{})

      assert length(result["records"]) == 2
      assert result["recordCount"] == 2
    end
  end

  describe "simulation" do
    test "simulate pay transitions status from WAITING to COMPLETE" do
      client = create_client()

      {:ok, created} =
        Client.PaymentRequests.create(client, %{
          "clientTransactionId" => "txn-sim-001",
          "paymentDescription" => "Simulation test"
        })

      id = created["PaymentRequestStatus"]["paymentRequestId"]

      # Simulate payment via HTTP
      response = Req.post!("#{MockServer.url()}/mock/simulate/pay/#{id}")

      assert response.status == 200
      assert response.body["status"] == "COMPLETE"

      # Verify via client
      {:ok, result} = Client.PaymentRequests.get(client, id)
      assert result["PaymentRequestStatus"]["status"] == "COMPLETE"
    end

    test "simulate pay returns 404 for unknown ID" do
      response = Req.post!("#{MockServer.url()}/mock/simulate/pay/unknown-id")

      assert response.status == 404
    end
  end

  describe "health check" do
    test "returns ok status" do
      response = Req.get!("#{MockServer.url()}/health")

      assert response.status == 200
      assert response.body["status"] == "ok"
    end
  end

  describe "mock control" do
    test "reset clears all data" do
      client = create_client()

      {:ok, _} =
        Client.PaymentRequests.create(client, %{
          "clientTransactionId" => "txn-reset-001",
          "paymentDescription" => "Reset test"
        })

      response = Req.post!("#{MockServer.url()}/_mock/reset")
      assert response.status == 200

      {:ok, result} = Client.PaymentRequests.search(client, %{})
      assert result["records"] == []
    end

    test "get_state returns current state" do
      client = create_client()

      {:ok, _} =
        Client.PaymentRequests.create(client, %{
          "clientTransactionId" => "txn-state-001",
          "paymentDescription" => "State test"
        })

      response = Req.get!("#{MockServer.url()}/_mock/state")
      assert response.status == 200
      assert length(response.body["payment_requests"]) == 1
    end
  end
end
