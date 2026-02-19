defmodule Azupay.MockServer.Webhook do
  @moduledoc """
  Delivers webhook callbacks for the mock server.

  When a payment request transitions to COMPLETE and has a
  `paymentNotification` configured, fires an async HTTP POST
  to the notification URL with the payment request data.
  """

  require Logger

  @doc """
  Fires a webhook callback asynchronously if the payment request
  has a payment notification URL configured.

  Takes the raw PaymentRequest schema struct and the formatted API response.
  Does not block the caller — uses TaskSupervisor for async delivery.
  """
  def maybe_deliver(%{payment_notification: nil}, _api_response), do: :ok
  def maybe_deliver(%{payment_notification: %{} = notification}, api_response) do
    url = notification["paymentNotificationEndpointUrl"]
    auth = notification["paymentNotificationAuthorizationHeaderValue"]

    if url && url != "" do
      payload = build_payload(api_response)

      Task.Supervisor.start_child(
        Azupay.MockServer.TaskSupervisor,
        fn -> deliver(url, auth, payload) end
      )
    end

    :ok
  end

  def maybe_deliver(_pr, _api_response), do: :ok

  defp build_payload(api_response) do
    payment_amount = api_response["PaymentRequest"]["paymentAmount"]
    completed_datetime = DateTime.utc_now() |> DateTime.to_iso8601()

    status_additions = %{
      "completedDatetime" => completed_datetime,
      "amountReceived" => payment_amount,
      "settledBy" => "PayID"
    }

    update_in(api_response, ["PaymentRequestStatus"], fn status ->
      Map.merge(status, status_additions)
    end)
  end

  defp deliver(url, auth, payload) do
    headers = [{"content-type", "application/json"}]
    headers = if auth, do: [{"authorization", auth} | headers], else: headers

    case Req.post(url: url, headers: headers, json: payload) do
      {:ok, %{status: status}} ->
        Logger.info("[Azupay.MockServer.Webhook] Delivered callback to #{url} — status: #{status}")

      {:error, reason} ->
        Logger.warning(
          "[Azupay.MockServer.Webhook] Failed to deliver callback to #{url}: #{inspect(reason)}"
        )
    end
  end
end
