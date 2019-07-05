defmodule RssWatcher.MixProject do
  use Mix.Project

  def project do
    [
      app: :rss_watcher,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Docs
      name: "RssWatcher",
      source_url: "https://github.com/matthewoden/rss_watcher",
      homepage_url: "https://github.com/matthewoden/rss_watcher",
      package: package(),
      docs: [
        # The main page in the docs
        main: "RssWatcher",
        extras: ["README.md"]
      ]
    ]
  end

  def application() do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps() do
    [
      {:fiet, "~> 0.2.1", optional: true},
      {:tesla, "~> 1.2.1", optional: true},
      {:jason, ">= 1.0.0", optional: true},
      {:timex, "~> 3.0", optional: true},
      {:bypass, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      description: "Create a process to monitor an Atom/RSS 2.0 feed, and dispatch updates.",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/matthewoden/rss_watcher"}
    ]
  end
end
