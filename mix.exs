defmodule EctoHomoiconicEnum.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do [
    app: :ecto_homoiconic_enum,

    name: "EctoHomoiconicEnum",
    description: "Adds support for enumerated types to Ecto. Unlike ecto_enum, these enums assume the database will take and return the enum's values by their string representations.",
    version: @version,
    elixir: "~> 1.4",
    package: package(),

    docs: [
      source_ref: "#{@version}",
      source_url: "https://github.com/meetwalter/ecto_homoiconic_enum"
    ],

    build_path: "_build",
    deps_path: "_deps",
    test_paths: ["test"],

    deps: deps()
  ] end

  defp package do [
    maintainers: ["Michael Williams"],
    contributors: ["Michael Williams", "Gabriel Jaldon"],
    licenses: ["MIT"],
    links: %{github: "https://github.com/meetwalter/ecto_homoiconic_enum"},
    files: ~w(mix.exs README.md lib)
  ] end

  def application do [
    extra_applications: [:logger]
  ] end

  defp deps do [
    {:ecto, "~> 2.1"},
    {:postgrex, "~> 0.13", optional: true},
    {:ex_doc, ">= 0.0.0", only: :dev}
  ] end
end
