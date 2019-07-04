# RssWatcher

Worker that fetches RSS feeds, finds new updates, and dispatches those to a callback.

A small worker that watches a single RSS feed, parses the changes, and invokes a function for each update.

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

```elixir
  # MFA format
  {RssWatcher,
    [
      "http://example.com/rss",
      {Notifications, broadcast, ["#channel_id"]},
      refresh_interval: 60
    ]
  }

  # Anonymous function format
  {RssWatcher,
    [
      "http://example.com/rss",
      fn xml -> Notifications.broadcast(xml) end,
      refresh_interval: 60
    ]
  }

  # Suspended reference format
  {RssWatcher,
    [
      "http://example.com/rss",
      &Notifications.broadcast/1,
      refresh_interval: 60
    ]
  }
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `rss_watcher` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rss_watcher, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/rss_watcher](https://hexdocs.pm/rss_watcher).
