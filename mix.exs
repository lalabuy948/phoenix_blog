defmodule PhoenixBlog.MixProject do
  use Mix.Project

  @version "0.1.5"
  @source_url "https://github.com/lalabuy948/phoenix_blog"

  def project do
    [
      app: :phoenix_blog,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "Plug-and-play blog engine for Phoenix with Editor.js integration",
      source_url: @source_url,
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.10"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.0"},
      {:plug, "~> 1.16"},
      {:jason, "~> 1.4"},

      # Database adapters (optional, dev/test only)
      {:postgrex, ">= 0.0.0", optional: true},
      {:myxql, ">= 0.0.0", optional: true},
      {:ecto_sqlite3, ">= 0.0.0", optional: true},

      # Dev/test
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["lalabuy948"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib priv/static .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
