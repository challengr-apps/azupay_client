defmodule Azupay.Webhook.Plug do
  @moduledoc """
  Plug for receiving AzuPay webhook notifications.

  Parses the JSON payload, infers the event type from the top-level keys,
  extracts the `Authorization` header, and delegates to your handler module.
  Authentication is handled by the handler — see `Azupay.Webhook.Handler`
  for details.

  The event type is inferred by checking for known top-level keys in the
  payload (e.g. `"PaymentRequest"`, `"Payment"`, `"PaymentAgreement"`, etc.).
  If no known key is found, the event type is `"unknown"`.

  ## Options

    * `:handler` — Module implementing `Azupay.Webhook.Handler` (required)
    * `:environment` — The environment atom, e.g. `:uat` or `:prod` (required).
      Passed to the handler in the context map.

  ## Example

      # Mount once per environment at different paths
      forward "/webhooks/azupay/uat", Azupay.Webhook.Plug,
        environment: :uat,
        handler: MyApp.AzupayWebhookHandler

      forward "/webhooks/azupay/prod", Azupay.Webhook.Plug,
        environment: :prod,
        handler: MyApp.AzupayWebhookHandler
  """

  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts) do
    %{
      handler: Keyword.fetch!(opts, :handler),
      environment: Keyword.fetch!(opts, :environment)
    }
  end

  @impl true
  def call(%{method: "POST"} = conn, config) do
    with {:ok, conn, payload} <- read_json_body(conn) do
      event_type = infer_event_type(payload)
      authorization = get_authorization_header(conn)

      context = %{
        environment: config.environment,
        authorization: authorization
      }

      case config.handler.handle_event(event_type, payload, context) do
        :ok ->
          conn |> send_resp(200, "") |> halt()

        {:error, :unauthorized} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(401, Jason.encode!(%{"error" => "unauthorized"}))
          |> halt()

        {:error, _reason} ->
          conn |> send_resp(500, "") |> halt()
      end
    else
      {:error, _reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{"error" => "bad_request"}))
        |> halt()
    end
  end

  def call(conn, _config) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(405, Jason.encode!(%{"error" => "method_not_allowed"}))
    |> halt()
  end

  @event_type_keys [
    {"PaymentRequest", "PaymentRequest"},
    {"Payment", "Payment"},
    {"PaymentAgreement", "PaymentAgreement"},
    {"PaymentAgreementAmendment", "PaymentAgreementAmendment"},
    {"PaymentInitiation", "PaymentInitiation"},
    {"client", "ClientEnabled"}
  ]

  defp infer_event_type(payload) do
    Enum.find_value(@event_type_keys, "unknown", fn {key, event_type} ->
      if Map.has_key?(payload, key), do: event_type
    end)
  end

  # When mounted behind Phoenix's Plug.Parsers, the body has already been
  # read and parsed into conn.body_params. Use that when available, and
  # fall back to reading the raw body for non-Phoenix usage.
  defp read_json_body(%{body_params: %Plug.Conn.Unfetched{}} = conn) do
    case Plug.Conn.read_body(conn) do
      {:ok, body, conn} ->
        case Jason.decode(body) do
          {:ok, payload} when is_map(payload) -> {:ok, conn, payload}
          _ -> {:error, :invalid_json}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp read_json_body(%{body_params: %{} = params} = conn) when params != %{} do
    {:ok, conn, params}
  end

  defp read_json_body(_conn), do: {:error, :invalid_json}

  defp get_authorization_header(conn) do
    case get_req_header(conn, "authorization") do
      [value] -> value
      _ -> nil
    end
  end
end
