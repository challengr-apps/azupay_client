defmodule Azupay.Webhook.Plug do
  @moduledoc """
  Plug for receiving AzuPay webhook notifications.

  Parses the JSON payload, extracts the event type and `Authorization` header,
  and delegates to your handler module. Authentication is handled by the
  handler — see `Azupay.Webhook.Handler` for details.

  ## Options

    * `:handler` — Module implementing `Azupay.Webhook.Handler` (required)
    * `:environment` — The environment atom, e.g. `:uat` or `:prod` (required).
      Passed to the handler in the context map.
    * `:event_type_key` — Key to extract the event type from the payload
      (default: `"entityType"`)

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
      environment: Keyword.fetch!(opts, :environment),
      event_type_key: Keyword.get(opts, :event_type_key, "entityType")
    }
  end

  @impl true
  def call(%{method: "POST"} = conn, config) do
    with {:ok, conn, payload} <- read_json_body(conn) do
      event_type = Map.get(payload, config.event_type_key, "unknown")
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

  defp read_json_body(conn) do
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

  defp get_authorization_header(conn) do
    case get_req_header(conn, "authorization") do
      [value] -> value
      _ -> nil
    end
  end
end
