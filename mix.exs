defmodule Azupay.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/challengr-apps/azupay_client"

  def project do
    [
      app: :azupay,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir client for the AzuPay Payments API",
      package: package(),
      name: "Azupay",
      source_url: @source_url,
      homepage_url: "https://hexdocs.pm/azupay",
      docs: [
        main: "readme",
        extras: ["README.md", "LICENSE", "CHANGELOG.md"],
        source_ref: "v#{@version}"
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Azupay.Application, []}
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5.0"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.14", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
