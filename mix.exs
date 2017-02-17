defmodule EctoEnum.Mixfile do
  use Mix.Project

  @version "0.4.0"

  def project do [
    app: :ecto_enum,

    name: "EctoEnum",
    description: "Adds support for enumerated types to Ecto.",
    version: @version,
    elixir: "~> 1.2",
    package: package,

    docs: [
      source_ref: "#{@version}",
      source_url: "https://github.com/mtwilliams/ecto_enum"
    ],

    build_path: "_build",
    deps_path: "_deps",
    test_paths: ["test"],

    deps: deps
  ] end

  defp package do
    [contributors: ["Gabriel Jaldon"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/mtwilliams/ecto_enum"},
     files: ~w(mix.exs README.md CHANGELOG.md lib)]
  end

  def application do
    [applications: [:logger, :ecto]]
  end

  defp deps do
    [{:ecto, "~> 2.0"},
     {:postgrex, "~> 0.12.0", optional: true},
     {:ex_doc, "~> 0.11", only: :docs},
     {:earmark, "~> 0.1", only: :docs},
     {:inch_ex, ">= 0.0.0", only: :docs}]
  end
end
