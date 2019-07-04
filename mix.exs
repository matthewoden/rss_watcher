defmodule RssWatcher.MixProject do
  use Mix.Project

  def project do
    [
      app: :rss_watcher,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application() do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:fiet, "~> 0.2.1", optional: true},
      {:tesla, "~> 1.2.1", optional: true},
      {:jason, ">= 1.0.0", optional: true},
      {:timex, "~> 3.0", optional: true},
      {:bypass, "~> 1.0", only: :test}
    ]
  end
end
