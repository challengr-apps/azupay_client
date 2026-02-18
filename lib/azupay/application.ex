defmodule Azupay.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [] ++ maybe_mock_server()

    opts = [strategy: :one_for_one, name: Azupay.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp maybe_mock_server do
    mock_config = Application.get_env(:azupay, :mock_server, [])

    if mock_config[:enabled] && mock_config[:repo] do
      [Azupay.MockServer.Supervisor]
    else
      []
    end
  end
end
