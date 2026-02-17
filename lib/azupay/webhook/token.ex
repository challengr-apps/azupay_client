defmodule Azupay.Webhook.Token do
  @moduledoc false

  # Internal module for JWT generation and verification.
  # Uses HS256 (symmetric) signing with a shared secret key.

  @default_ttl 3600

  @doc """
  Generates a signed JWT access token.

  ## Options

    * `:ttl` — Token lifetime in seconds (default: #{@default_ttl})
    * `:issuer` — Value for the `iss` claim
    * `:subject` — Value for the `sub` claim

  """
  @spec generate(String.t(), keyword()) :: {:ok, String.t(), pos_integer()}
  def generate(signing_key, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    now = System.system_time(:second)

    claims = %{
      "iat" => now,
      "exp" => now + ttl,
      "jti" => generate_jti()
    }

    claims = put_optional(claims, "iss", Keyword.get(opts, :issuer))
    claims = put_optional(claims, "sub", Keyword.get(opts, :subject))

    signer = Joken.Signer.create("HS256", signing_key)

    case Joken.encode_and_sign(claims, signer) do
      {:ok, token, _claims} -> {:ok, token, ttl}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Verifies a JWT access token and returns its claims.
  """
  @spec verify(String.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def verify(token, signing_key) do
    signer = Joken.Signer.create("HS256", signing_key)

    case Joken.verify(token, signer) do
      {:ok, claims} -> validate_expiry(claims)
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_expiry(%{"exp" => exp} = claims) do
    if System.system_time(:second) < exp do
      {:ok, claims}
    else
      {:error, :token_expired}
    end
  end

  defp validate_expiry(claims), do: {:ok, claims}

  defp generate_jti do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end

  defp put_optional(claims, _key, nil), do: claims
  defp put_optional(claims, key, value), do: Map.put(claims, key, value)
end
