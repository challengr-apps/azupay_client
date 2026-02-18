defmodule Azupay.MockServer do
  @moduledoc """
  Mock server for testing AzuPay API integrations.

  The mock server provides a local HTTP server that simulates the AzuPay Payments API,
  allowing you to test your integration without making real API calls.

  ## Configuration

  Add to your `config/test.exs` or `config/dev.exs`:

      config :azupay, :mock_server,
        enabled: true,
        port: 4502,
        repo: MyApp.Repo

  ## Embedded Mode

  When running inside a Phoenix application, use embedded mode to serve
  the mock API through your Phoenix router:

      config :azupay, :mock_server,
        enabled: true,
        embedded: true,
        base_url: "http://localhost:4000/azupay-mock",
        repo: MyApp.Repo

  Then forward routes in your Phoenix router:

      forward "/azupay-mock", Azupay.MockServer.Router

  ## Database Setup

  Create a migration in your application:

      defmodule MyApp.Repo.Migrations.AddAzupayMockServer do
        use Ecto.Migration

        def up, do: Azupay.MockServer.Migrations.up(version: 1)
        def down, do: Azupay.MockServer.Migrations.down(version: 1)
      end

  Run `mix ecto.migrate` to create the mock server tables.

  ## Usage in Tests

      setup do
        Azupay.MockServer.reset()
        :ok
      end

      test "creates payment request" do
        client = Azupay.Client.new(environment: :uat)

        {:ok, result} = Azupay.Client.PaymentRequests.create(client, %{
          "clientTransactionId" => "txn-001",
          "paymentDescription" => "Test payment"
        })

        assert result["paymentRequestId"]
        assert result["status"] == "WAITING"
      end

  ## Available Endpoints

  The mock server implements the following AzuPay API endpoints:

  - `POST /v1/paymentRequest` - Create a payment request
  - `GET /v1/paymentRequest?id=X` - Get a payment request
  - `DELETE /v1/paymentRequest?id=X` - Delete a payment request
  - `POST /v1/paymentRequest/refund?id=X` - Refund a payment request
  - `POST /v1/paymentRequest/search` - Search payment requests

  **Simulation:**
  - `POST /mock/simulate/pay/:id` - Simulate a payment being received

  **Mock Control:**
  - `POST /_mock/reset` - Clear all mock data
  - `GET /_mock/state` - Get current mock state
  """

  alias Azupay.MockServer.State

  @doc """
  Returns true if the mock server is enabled and configured.
  """
  def enabled? do
    config = Application.get_env(:azupay, :mock_server, [])
    config[:enabled] == true && config[:repo] != nil
  end

  @doc """
  Returns the mock server base URL.

  In embedded mode, returns the configured `:base_url`.
  Otherwise, returns `http://localhost:{port}`.
  """
  def url do
    config = Application.get_env(:azupay, :mock_server, [])

    if config[:base_url] do
      config[:base_url]
    else
      port = config[:port] || 4502
      "http://localhost:#{port}"
    end
  end

  @doc """
  Returns the port the mock server is running on.
  Returns nil in embedded mode.
  """
  def port do
    config = Application.get_env(:azupay, :mock_server, [])

    if config[:embedded] do
      nil
    else
      config[:port] || 4502
    end
  end

  @doc """
  Returns true if running in embedded mode.
  """
  def embedded? do
    config = Application.get_env(:azupay, :mock_server, [])
    config[:embedded] == true
  end

  @doc """
  Resets all mock data.
  Call this in your test setup to ensure a clean state.
  """
  def reset do
    State.reset()
  end

  @doc """
  Seeds a payment request into the mock database.

  ## Examples

      {:ok, pr} = Azupay.MockServer.seed_payment_request(%{
        "clientTransactionId" => "txn-001",
        "paymentDescription" => "Test payment",
        "paymentAmount" => 25.00
      })
  """
  def seed_payment_request(params) when is_map(params) do
    params = Map.put_new(params, "clientId", "seed_client_id")
    State.create_payment_request(params)
  end

  @doc """
  Returns the current mock state for debugging.
  """
  def get_state do
    State.get_state()
  end
end
