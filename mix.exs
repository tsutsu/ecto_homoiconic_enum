defmodule EctoHomoiconicEnum.Mixfile do
  use Mix.Project

  @version File.read!("VERSION") |> String.trim

  @description """
    Adds support for enumerated types to Ecto. Unlike ecto_enum, these enums assume the database will take and return the enum's values by their string representations.
  """

  def project, do: [
    app: :ecto_homoiconic_enum,
    version: @version,
    elixir: "~> 1.5",
    description: @description,
    consolidate_protocols: not Mix.env in [:dev, :test],
    deps: deps(),
    package: package()
  ]

  def application, do: [
    extra_applications: [:logger]
  ]

  defp package, do: [
    maintainers: ["Levi Aul"],
    contributors: ["Levi Aul", "Michael Williams", "Gabriel Jaldon"],
    licenses: ["MIT"],
    links: %{github: "https://github.com/tsutsu/ecto_homoiconic_enum"},
    files: ~w(mix.exs lib README.md VERSION)
  ]

  defp deps do [
    {:ecto, "~> 2.2"},
    {:postgrex, "~> 0.13", optional: true},
    {:ex_doc, ">= 0.0.0", only: :dev}
  ] end
end
