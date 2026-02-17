defmodule Azupay.Webhook.TokenEndpoint do
  @moduledoc """
  OAuth2 token endpoint Plug for AzuPay webhook authentication.

  AzuPay uses the OAuth2 Client Credentials grant to obtain Bearer tokens
  before sending webhook notifications. Mount this Plug at a path that you
  configure as the `tokenUrl` in AzuPay's webhook settings.

  ## Options

    * `:client_id` — Expected client ID (required)
    * `:client_secret` — Expected client secret (required)
    * `:signing_key` — Secret key for signing JWTs; must match the key
      used in `Azupay.Webhook.Plug` (required)
    * `:token_ttl` — Token lifetime in seconds (default: 3600)
    * `:issuer` — Optional JWT `iss` claim

  ## Example

      forward "/webhooks/azupay/token", Azupay.Webhook.TokenEndpoint,
        client_id: "azupay-client",
        client_secret: "secret-value",
        signing_key: "my-signing-key"

  AzuPay can send credentials either in the `Authorization` header (HTTP Basic)
  or in the request body (form-urlencoded), controlled by the `sendClientCredentialsIn`
  setting. This endpoint supports both.
  """

  @behaviour Plug

  import Plug.Conn

  alias Azupay.Webhook.Token

  @impl true
  def init(opts) do
    %{
      client_id: Keyword.fetch!(opts, :client_id),
      client_secret: Keyword.fetch!(opts, :client_secret),
      signing_key: Keyword.fetch!(opts, :signing_key),
      token_ttl: Keyword.get(opts, :token_ttl, 3600),
      issuer: Keyword.get(opts, :issuer)
    }
  end

  @impl true
  def call(%{method: "POST"} = conn, config) do
    with {:ok, conn, params} <- read_form_body(conn),
         {:ok, grant_type} <- fetch_grant_type(params),
         :ok <- validate_grant_type(grant_type),
         {:ok, client_id, client_secret} <- extract_credentials(conn, params),
         :ok <- verify_credentials(client_id, client_secret, config) do
      issue_token(conn, config)
    else
      {:error, :invalid_grant_type} ->
        json_error(
          conn,
          400,
          "unsupported_grant_type",
          "Only client_credentials grant is supported"
        )

      {:error, :missing_grant_type} ->
        json_error(conn, 400, "invalid_request", "Missing required parameter: grant_type")

      {:error, :missing_credentials} ->
        json_error(conn, 401, "invalid_client", "Client credentials are required")

      {:error, :invalid_credentials} ->
        json_error(conn, 401, "invalid_client", "Invalid client credentials")

      {:error, _reason} ->
        json_error(conn, 400, "invalid_request", "Malformed request")
    end
  end

  def call(conn, _config) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(405, Jason.encode!(%{"error" => "method_not_allowed"}))
    |> halt()
  end

  defp read_form_body(conn) do
    case Plug.Conn.read_body(conn) do
      {:ok, body, conn} ->
        params = URI.decode_query(body)
        {:ok, conn, params}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_grant_type(params) do
    case Map.fetch(params, "grant_type") do
      {:ok, grant_type} -> {:ok, grant_type}
      :error -> {:error, :missing_grant_type}
    end
  end

  defp validate_grant_type("client_credentials"), do: :ok
  defp validate_grant_type(_), do: {:error, :invalid_grant_type}

  defp extract_credentials(conn, params) do
    case get_basic_auth(conn) do
      {:ok, client_id, client_secret} ->
        {:ok, client_id, client_secret}

      :error ->
        case {Map.fetch(params, "client_id"), Map.fetch(params, "client_secret")} do
          {{:ok, id}, {:ok, secret}} -> {:ok, id, secret}
          _ -> {:error, :missing_credentials}
        end
    end
  end

  defp get_basic_auth(conn) do
    with [auth_header] <- get_req_header(conn, "authorization"),
         "Basic " <> encoded <- auth_header,
         {:ok, decoded} <- Base.decode64(encoded),
         [client_id, client_secret] <- String.split(decoded, ":", parts: 2) do
      {:ok, client_id, client_secret}
    else
      _ -> :error
    end
  end

  defp verify_credentials(client_id, client_secret, config) do
    if Plug.Crypto.secure_compare(client_id, config.client_id) and
         Plug.Crypto.secure_compare(client_secret, config.client_secret) do
      :ok
    else
      {:error, :invalid_credentials}
    end
  end

  defp issue_token(conn, config) do
    token_opts =
      [ttl: config.token_ttl]
      |> put_if(:issuer, config.issuer)
      |> put_if(:subject, config.client_id)

    case Token.generate(config.signing_key, token_opts) do
      {:ok, token, expires_in} ->
        body =
          Jason.encode!(%{
            "access_token" => token,
            "token_type" => "Bearer",
            "expires_in" => expires_in
          })

        conn
        |> put_resp_content_type("application/json")
        |> put_resp_header("cache-control", "no-store")
        |> send_resp(200, body)
        |> halt()

      {:error, _reason} ->
        json_error(conn, 500, "server_error", "Failed to generate token")
    end
  end

  defp json_error(conn, status, error, description) do
    body = Jason.encode!(%{"error" => error, "error_description" => description})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, body)
    |> halt()
  end

  defp put_if(opts, _key, nil), do: opts
  defp put_if(opts, key, value), do: Keyword.put(opts, key, value)
end
