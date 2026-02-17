defmodule Azupay.Client do
  @moduledoc """
  Main client module for the AzuPay Payments API.

  This module provides a convenient interface for interacting with the AzuPay API
  using API key authentication and the Req HTTP client library.

  ## Configuration

  Configure the client in your config files:

      config :azupay,
        environments: [
          uat: [
            base_url: "https://api-uat.azupay.com.au/v1",
            api_key: "your_api_key",
            client_id: "your_client_id"
          ],
          prod: [
            base_url: "https://api.azupay.com.au/v1",
            api_key: "your_api_key",
            client_id: "your_client_id"
          ]
        ]

  ## Usage

      client = Azupay.Client.new(environment: :uat)
      {:ok, payment_request} = Azupay.Client.PaymentRequests.create(client, %{...})
  """

  @type t :: %__MODULE__{
          environment: atom(),
          base_url: String.t(),
          api_key: String.t(),
          client_id: String.t(),
          req_options: keyword()
        }

  defstruct [
    :environment,
    :base_url,
    :api_key,
    :client_id,
    req_options: []
  ]

  @doc """
  Creates a new AzuPay API client.

  Reads API key, client ID, and base URL from application config for the given environment.

  ## Options

    * `:environment` - The environment to use (`:uat` or `:prod`) (required)
    * `:base_url` - Override the configured base URL (optional)
    * `:api_key` - Override the configured API key (optional)
    * `:client_id` - Override the configured client ID (optional)
    * `:req_options` - Additional options to pass to Req (optional)

  ## Examples

      client = Azupay.Client.new(environment: :uat)
      client = Azupay.Client.new(environment: :prod)
      client = Azupay.Client.new(environment: :uat, api_key: "override_key")
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    environment = opts[:environment] || raise("environment is required (e.g., :uat or :prod)")
    env_config = get_environment_config(environment)

    base_url =
      opts[:base_url] ||
        (env_config && Keyword.get(env_config, :base_url)) ||
        raise("base_url not configured for environment: #{inspect(environment)}")

    api_key =
      opts[:api_key] ||
        (env_config && Keyword.get(env_config, :api_key)) ||
        raise("api_key not configured for environment: #{inspect(environment)}")

    client_id =
      opts[:client_id] ||
        (env_config && Keyword.get(env_config, :client_id)) ||
        raise("client_id not configured for environment: #{inspect(environment)}")

    %__MODULE__{
      environment: environment,
      base_url: base_url,
      api_key: api_key,
      client_id: client_id,
      req_options: opts[:req_options] || []
    }
  end

  @doc """
  Creates a new client for the UAT environment.

  ## Examples

      client = Azupay.Client.uat()
  """
  @spec uat(keyword()) :: t()
  def uat(opts \\ []) do
    opts
    |> Keyword.put(:environment, :uat)
    |> new()
  end

  defp get_environment_config(environment) do
    config = Application.get_env(:azupay, :environments, [])
    Keyword.get(config, environment)
  end
end
