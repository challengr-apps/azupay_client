defmodule Azupay.Webhook.TokenTest do
  use ExUnit.Case, async: true

  alias Azupay.Webhook.Token

  @signing_key "test-signing-key-at-least-32-chars!"

  describe "generate/2" do
    test "returns a signed JWT and expiry" do
      assert {:ok, token, 3600} = Token.generate(@signing_key)
      assert is_binary(token)
    end

    test "respects custom TTL" do
      assert {:ok, _token, 600} = Token.generate(@signing_key, ttl: 600)
    end

    test "includes optional issuer and subject claims" do
      {:ok, token, _ttl} =
        Token.generate(@signing_key, issuer: "test-issuer", subject: "client-1")

      {:ok, claims} = Token.verify(token, @signing_key)

      assert claims["iss"] == "test-issuer"
      assert claims["sub"] == "client-1"
    end

    test "includes iat, exp, and jti claims" do
      {:ok, token, _ttl} = Token.generate(@signing_key)
      {:ok, claims} = Token.verify(token, @signing_key)

      assert is_integer(claims["iat"])
      assert is_integer(claims["exp"])
      assert claims["exp"] > claims["iat"]
      assert is_binary(claims["jti"])
    end
  end

  describe "verify/2" do
    test "verifies a valid token" do
      {:ok, token, _ttl} = Token.generate(@signing_key)
      assert {:ok, claims} = Token.verify(token, @signing_key)
      assert is_map(claims)
    end

    test "rejects a token signed with a different key" do
      {:ok, token, _ttl} = Token.generate(@signing_key)
      assert {:error, _reason} = Token.verify(token, "wrong-key-that-is-long-enough!!")
    end

    test "rejects an expired token" do
      {:ok, token, _ttl} = Token.generate(@signing_key, ttl: -1)
      assert {:error, :token_expired} = Token.verify(token, @signing_key)
    end

    test "rejects a malformed token" do
      assert {:error, _reason} = Token.verify("not-a-jwt", @signing_key)
    end
  end
end
