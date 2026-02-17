defmodule Azupay do
  @moduledoc """
  Elixir client for the AzuPay Payments API.

  ## Quick Start

      # Create a client for the UAT environment
      client = Azupay.Client.new(environment: :uat)

      # Create a payment request
      {:ok, payment_request} = Azupay.Client.PaymentRequests.create(client, %{
        "clientTransactionId" => "txn-123",
        "paymentDescription" => "Invoice payment"
      })

  ## Configuration

      config :azupay,
        environments: [
          uat: [
            base_url: "https://api-uat.azupay.com.au/v1",
            api_key: "your_api_key",
            client_id: "your_client_id"
          ],
          prod: [
            base_url: "https://api.azupay.com.au/v1",
            api_key: "your_api_key",
            client_id: "your_client_id"
          ]
        ]
  """
end
