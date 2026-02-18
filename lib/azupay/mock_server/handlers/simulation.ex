defmodule Azupay.MockServer.Handlers.Simulation do
  @moduledoc """
  Handles simulation and mock control endpoints for the mock server.
  """

  alias Azupay.MockServer.State
  alias Azupay.MockServer.Responses

  @doc """
  Handles POST /mock/simulate/pay/:id - Simulate a payment being received.
  """
  def pay(conn, id) do
    case State.simulate_payment(id) do
      {:ok, payment_request} ->
        Responses.ok(conn, %{
          "paymentRequestId" => payment_request["PaymentRequestStatus"]["paymentRequestId"],
          "status" => payment_request["PaymentRequestStatus"]["status"],
          "message" => "Payment simulated successfully"
        })

      {:error, :not_found} ->
        Responses.not_found(conn, "Payment request not found")

      {:error, {:invalid_state, message}} ->
        Responses.error(conn, 422, "invalid_state", message)
    end
  end

  @doc """
  Handles POST /_mock/reset - Clear all mock data.
  """
  def reset(conn) do
    State.reset()
    Responses.ok(conn, %{"status" => "reset"})
  end

  @doc """
  Handles GET /_mock/state - Return all mock state for debugging.
  """
  def get_state(conn) do
    state = State.get_state()
    Responses.ok(conn, %{"payment_requests" => state})
  end
end
