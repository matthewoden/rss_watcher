defmodule RssWatcher do
  @moduledoc """
  A small worker that watches a single RSS feed, parses the changes, and invokes a function for each new update.

  ## Usage
  In your supervisor, add an instace of the RssWatcher worker. As arguments,
  provide the url, the callback in the form of {Module, function, arguments}, or
  an anonymous function, and any additional configuration.

  ### Dependancies

  Add the following to your dependancies:

  ```elixir
  {:rss_watcher, "~> 0.1.0"}
  ```

  For easy mode, you can use the default adapters for parsing and http requests.
  They require the following dependancies:

  ```
  {:tesla, "~> 1.2.1"}, # HTTP adapter - see RssWatcher.HTTP.Adapter
                        # module for additional configuration

  {:fiet, "~> 0.2.1"}, # RSS and timestamp parsing.
  {:timex, "~> 3.0"}
  ```

  ### Url
  The url should be a string, which resolves to an RSS feed.

  ### Callback
  The callback can be in the form of `{module, function, arguments}`, or
  an anonymous/suspended function.

  If `{module, function, arguments}` format, the callback will be dispatched with
  an additional argument - the parsed XML. Otherwise, the parsed XML will be
  the only argument provided. See below for examples.

  ### Options
  The third argument is a keyword list, configuring the `RssWatcher.Subscription`
  that handles fetching and dispatching updates.

  - `:refresh_interval` - integer. How often the feed is checked, in seconds. Defautls to `60`.
  - `:rss_parser` - Atom/RSS 2.0 parser module. Defaults to `RssWatcher.Feed.Adapter.Fiet`,
  - `:rss_parser_options`- options for the above parser. Defaults to `[]`,
  - `:http_client` - HTTP client for fetching updates. Defaults to `RssWatcher.HTTP.Adapter.Tesla`,
  - `:http_client_options` - options for the above client. Default to `[]`. See adapter module for configuration options.

  ### Examples

    {RssWatcher,
      [
        "http://example.com/rss",
        {Notifications, broadcast, ["#channel_id"]},
        refresh_interval: 60
      ]
    }

    {RssWatcher,
      [
        "http://example.com/rss",
        fn xml -> Notifications.broadcast(xml) end,
        refresh_interval: 60
      ]
    }

    {RssWatcher,
      [
        "http://example.com/rss",
        &Notifications.broadcast/1,
        refresh_interval: 60
      ]
    }

  """
  use GenServer
  alias RssWatcher.{Subscription}
  require Logger

  @type url :: String.t()
  @type callback :: {module, atom} | function
  @type options :: [refresh_interval: integer]

  @doc """
  Starts the worker process. See moduledoc for options.
  """
  @spec start_link(url, callback, options) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(url, fun, opts \\ []) do
    state = %{subscription: Subscription.new(url, fun, opts)}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  @doc false
  def init(state) do
    schedule_poll(state.subscription.fetch_interval * 1000)
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
