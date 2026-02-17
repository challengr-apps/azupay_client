defmodule Azupay.Webhook.Plug do
  @moduledoc """
  Plug for receiving AzuPay webhook notifications.

  Verifies authentication, parses the JSON payload, and delegates to your
  handler module.

  ## Options

    * `:handler` — Module implementing `Azupay.Webhook.Handler` (required)
    * `:auth` — Authentication mode or list of modes (required):
      * `{:api_key, key}` — Verify the `Authorization` header matches `key`
      * `{:oauth2, signing_key: key}` — Verify the `Authorization: Bearer` JWT
        using the given signing key (must match `Azupay.Webhook.TokenEndpoint`)
      * A list of the above to accept either mode (tried in order, first match wins)
    * `:event_type_key` — Key to extract the event type from the payload
      (default: `"entityType"`)

  ## Example

      # API key auth only
      forward "/webhooks/azupay", Azupay.Webhook.Plug,
        auth: {:api_key, "my-webhook-key"},
        handler: MyApp.AzupayWebhookHandler

      # OAuth2 auth only
      forward "/webhooks/azupay", Azupay.Webhook.Plug,
        auth: {:oauth2, signing_key: "my-signing-key"},
        handler: MyApp.AzupayWebhookHandler

      # Both modes — accepts either API key or OAuth2 Bearer token
      forward "/webhooks/azupay", Azupay.Webhook.Plug,
        auth: [
          {:api_key, "my-webhook-key"},
          {:oauth2, signing_key: "my-signing-key"}
        ],
        handler: MyApp.AzupayWebhookHandler
  """

  @behaviour Plug

  import Plug.Conn

  alias Azupay.Webhook.Token

  @impl true
  def init(opts) do
    auth =
      case Keyword.fetch!(opts, :auth) do
        methods when is_list(methods) -> methods
        single -> [single]
      end

    %{
      handler: Keyword.fetch!(opts, :handler),
      auth: auth,
      event_type_key: Keyword.get(opts, :event_type_key, "entityType")
    }
  end

  @impl true
  def call(%{method: "POST"} = conn, config) do
    with {:ok, conn, payload} <- read_json_body(conn),
         :ok <- verify_auth(conn, config.auth) do
      event_type = Map.get(payload, config.event_type_key, "unknown")

      case config.handler.handle_event(event_type, payload) do
        :ok ->
          conn |> send_resp(200, "") |> halt()

        {:error, _reason} ->
          conn |> send_resp(500, "") |> halt()
      end
    else
      {:error, :unauthorized} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{"error" => "unauthorized"}))
        |> halt()

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

  defp verify_auth(conn, auth_methods) when is_list(auth_methods) do
    if Enum.any?(auth_methods, fn method -> verify_auth(conn, method) == :ok end) do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  defp verify_auth(conn, {:api_key, expected_key}) do
    case get_req_header(conn, "authorization") do
      [key] ->
        if Plug.Crypto.secure_compare(key, expected_key) do
          :ok
        else
          {:error, :unauthorized}
        end

      _ ->
        {:error, :unauthorized}
    end
  end

  defp verify_auth(conn, {:oauth2, opts}) do
    signing_key = Keyword.fetch!(opts, :signing_key)

    with [auth_header] <- get_req_header(conn, "authorization"),
         "Bearer " <> token <- auth_header,
         {:ok, _claims} <- Token.verify(token, signing_key) do
      :ok
    else
      _ -> {:error, :unauthorized}
    end
  end
end
