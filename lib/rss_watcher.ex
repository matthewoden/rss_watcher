defmodule RssWatcher do
  @moduledoc """
  A small worker that watches a single RSS feed, parses the changes, and dispatches
  updates.

  ## Installation

  ### Dependencies

  Add the following to your dependencies:

  ```elixir
  {:rss_watcher, "~> 0.1.0"}
  ```

  For _easy mode_, you can use the default adapters to fetch and parse
  RSS feeds. Just add the following to your dependancies, and you should be good
  to go.

  ``` elixir
  {:tesla, "~> 1.2.1"}, # For HTTP requests
  {:fiet, "~> 0.2.1"}, # For RSS parsing
  {:timex, "~> 3.0"}, # For timestamp parsing
  ```

  And add `Timex` to your list of applications.
  ``` elixir
  extra_applications: [ ...,  :timex]
  ```

  ### Adapters

  `RssWatcher.HTTP.Tesla` is provided by default. To use, add the following
  dependancies to your dependency list. See module configuration around middleware, and additional
  adapter options.

  ``` elixir
  {:tesla, "~> 1.2.1"}
  ```

  For RSS parsing, `RssWatcher.Feed.Fiet` is provided by default,
  and handles parsing XML and timestamps. To use, add the following dependencies
  to your dependency list.

  ``` elixir
  {:fiet, "~> 0.2.1"},
  {:timex, "~> 3.0"}
  ```

  And add timex to your list of applications.
  ``` elixir
  extra_applications: [ ...  :timex]
  ```
  """
  use GenServer
  alias RssWatcher.{Subscription}
  require Logger

  @type url :: String.t()
  @type callback :: {module, atom} | function
  @type options :: [refresh_interval: integer]

  @doc """
  RssWatcher is a worker, so the recommended usage is to add it as a child
  to your supervisor.

  ### API Example
  ``` elixir
  children = [
    {RssWatcher,
        url: "http://example.com/rss",
        callback: {Notifications, broadcast, ["#channel_id"]}
    }
  ]

  Supervisor.start_link(children, strategy: :one_for_one))
  ```

  Or, with a dynamic supervisor:

  ``` elixir

  children = [
    {DynamicSupervisor, strategy: :one_for_one, name: MyApp.RssSupervisor}
  ]

  Supervisor.start_link(children, strategy: :one_for_one)

  ...

  DynamicSupervisor.start_child(
    MyApp.RssSupervisor,
    {
      RssWatcher,
        url: "http://example.com/rss",
        callback: {Notifications, broadcast, ["#channel_id"]}
    }
  )

  ```

  Each `RssWatcher` worker requires at least a _url_, and a _callback_. Additional
  configuration can be provided to use alternate adapters.

  ### Url (required)
  The url should be a string, which resolves to an RSS feed.

  ### Callback (required)
  The callback can be in the form of `{module, function, arguments}`, or
  an anonymous/suspended function.

  If `{module, function, arguments}` format, the callback will be dispatched with
  an additional argument - the parsed XML. Otherwise, the parsed XML will be
  the only argument provided. See below for examples.

  ### Additional Configuration
  The configuration is provided as a keyword list. The available options (and their defaults)
  are listed below

  - `:refresh_interval` - integer. How often the feed is checked, in seconds. Defautls to `60`.
  - `:rss_parser` - Atom/RSS 2.0 parser module. Defaults to `RssWatcher.Feed.Fiet`,
  - `:rss_parser_options`- options for the above parser. Defaults to `[]`,
  - `:http_client` - HTTP client for fetching updates. Defaults to `RssWatcher.HTTP.Tesla`,
  - `:http_client_options` - options for the above client. Default to `[]`. See adapter module for configuration options.

  ### Examples

  ``` elixir
  {RssWatcher,
    url: "http://example.com/rss",
    callback: {Notifications, broadcast, ["#channel_id"]},
    refresh_interval: 60
  }

  {RssWatcher,
    url: "http://example.com/rss",
    callback: fn xml -> Notifications.broadcast(xml) end,
    refresh_interval: 60
  }

  {RssWatcher,
    url: "http://example.com/rss",
    callback: &Notifications.broadcast/1,
    refresh_interval: 60
  }
  ```
  """
  @spec start_link(Keyword.t()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(options) do
    with {url, options} when not is_nil(url) <- Keyword.pop(options, :url),
         {fun, options} when not is_nil(fun) <- Keyword.pop(options, :callback) do
      state = %{subscription: Subscription.new(url, fun, options)}
      GenServer.start_link(__MODULE__, state, name: __MODULE__)
    else
      _ ->
        raise ArgumentError,
          message:
            ":url and :callback options are required. Provided options: #{inspect(options)}"
    end
  end

  @impl true
  @doc false
  def init(state) do
    schedule_poll(state.subscription.refresh_interval * 1000)
    {:ok, state}
  end

  @impl true
  @doc false
  def handle_info(:poll, state) do
    subscription =
      case Subscription.find_updates(state.subscription) do
        {:ok, updated_subscription} ->
          Subscription.dispatch_pending(updated_subscription)

        {:error, reason} ->
          Logger.warn(fn ->
            "Unable to find updates for #{state.subscription.url}: #{inspect(reason)}"
          end)

          state.subscription
      end

    schedule_poll(subscription.refresh_interval * 1000)

    {:noreply, %{state | subscription: subscription}}
  end

  defp schedule_poll(time), do: Process.send_after(self(), :poll, time)
end
