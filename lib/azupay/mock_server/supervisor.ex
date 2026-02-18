defmodule Azupay.MockServer.Supervisor do
  @moduledoc """
  Supervisor for the AzuPay mock server.

  Starts the HTTP server (Bandit) when configured, unless in embedded mode.

  ## Embedded Mode

  When running inside a Phoenix application, you can use embedded mode to serve
  the mock API through your Phoenix router instead of starting a separate HTTP server.

  Set `embedded: true` to skip starting Bandit, then forward routes in your Phoenix router:

      forward "/azupay-mock", Azupay.MockServer.Router

  ## Configuration Options

    * `:enabled` - Whether to start the mock server (default: false)
    * `:repo` - The Ecto Repo module to use for persistence (required)
    * `:port` - The port to run the HTTP server on (default: 4502).
      Ignored when `embedded: true`.
    * `:embedded` - When true, skips starting the Bandit HTTP server (default: false)
    * `:base_url` - Override the base URL for generated links
  """

  use Supervisor

  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    config = Application.get_env(:azupay, :mock_server, [])

    if config[:enabled] && config[:repo] do
      embedded = config[:embedded] || false
      port = config[:port] || 4502

      children = [
        {Task.Supervisor, name: Azupay.MockServer.TaskSupervisor}
      ]

      children =
        if embedded do
          Logger.info("Azupay Mock Server starting in embedded mode")
          children
        else
          Logger.info("Azupay Mock Server starting on port #{port}")
          children ++ [{Bandit, plug: Azupay.MockServer.Router, port: port, scheme: :http}]
        end

      Supervisor.init(children, strategy: :one_for_one)
    else
      if config[:enabled] && !config[:repo] do
        Logger.warning(
          "Azupay Mock Server is enabled but no :repo is configured. " <>
            "Add `config :azupay, :mock_server, repo: MyApp.Repo` to start the mock server."
        )
      end

      Supervisor.init([], strategy: :one_for_one)
    end
  end
end
