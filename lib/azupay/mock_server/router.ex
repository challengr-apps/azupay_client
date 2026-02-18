defmodule Azupay.MockServer.Router do
  @moduledoc """
  HTTP router for the AzuPay mock server.
  """

  use Plug.Router

  alias Azupay.MockServer.Handlers.PaymentRequests
  alias Azupay.MockServer.Handlers.Simulation
  alias Azupay.MockServer.Responses

  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  # Payment request endpoints
  post "/v1/paymentRequest/refund" do
    PaymentRequests.refund(conn)
  end

  post "/v1/paymentRequest/search" do
    PaymentRequests.search(conn)
  end

  post "/v1/paymentRequest" do
    PaymentRequests.create(conn)
  end

  get "/v1/paymentRequest" do
    PaymentRequests.get(conn)
  end

  delete "/v1/paymentRequest" do
    PaymentRequests.delete(conn)
  end

  # Simulation endpoints
  post "/mock/simulate/pay/:id" do
    Simulation.pay(conn, id)
  end

  # Mock control endpoints
  post "/_mock/reset" do
    Simulation.reset(conn)
  end

  get "/_mock/state" do
    Simulation.get_state(conn)
  end

  # Health check
  get "/health" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "ok", server: "azupay_mock"}))
  end

  # Catch-all for unmatched routes
  match _ do
    Responses.not_found(conn, "Endpoint not found")
  end
end
