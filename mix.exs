defmodule Azupay.MixProject do
  use Mix.Project

  def project do
    [
      app: :azupay,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
