defmodule AutoUpdater.MixProject do
  use Mix.Project

  def project do
    [
      app: :auto_updater,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # For packaging
      description: "A library for making applications automatically update themselves.",
      package: [
        licenses: ["BSD-2-Clause"],
        links: %{"GitHub" => "https://github.com/frerich/auto_updater"}
      ]
    ]
  end

  def application do
    case Mix.env() do
      :test ->
        []

      _ ->
        [
          extra_applications: [:logger],
          mod: {AutoUpdater.Application, {}}
        ]
    end
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:req, "~> 0.5.0"},
      {:plug, "~> 1.0", only: [:test]},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
