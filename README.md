# RssWatcher

A small worker that watches a single RSS feed, parses the changes, and dispatches updates.

Online Docs: [https://hexdocs.pm/rss_watcher](https://hexdocs.pm/rss_watcher).

## Installation

### Dependancies

Add the following to your dependancies:

```elixir
{:rss_watcher, "~> 0.1.0"}
```

For _easy mode_, you can use the provided default adapters to fetch and parse
RSS feeds.

`RssWatcher.HTTP.Tesla` is provided by default. To use, add the following
dependancies to your dependancy list.

```
{:tesla, "~> 1.2.1"}, #
```

See module for `Tesla` configuration around middleware, and additional
adapter options.

---

For RSS parsing, `RssWatcher.Feed.Fiet` is provided by default,
and handles parsing XML and timestamps. To use, add the following dependancies
to your dependancy list.

```elixir
{:fiet, "~> 0.2.1"}, # RSS and timestamp parsing.
{:timex, "~> 3.0"}
```

And add timex to your list of applications.

```elixir
extra_applications: [ ...  :timex]
```

## Usage

RssWatcher is a worker, so the recommended usage is to add it as a child
to your supervisor.

### API Example

```elixir
children = [
  {RssWatcher,
    [
      "http://example.com/rss",
      {Notifications, broadcast, ["#channel_id"]},
      refresh_interval: 60
    ]
  }
]

Supervisor.start_link(children, strategy: :one_for_one))
```

Or, with a dynamic supervisor:

```elixir

children = [
  {DynamicSupervisor, strategy: :one_for_one, name: MyApp.RssSupervisor}
]

Supervisor.start_link(children, strategy: :one_for_one)

...

DynamicSupervisor.start_child(MyApp.RssSupervisor, {
  RssWatcher,
    [
      "http://example.com/rss",
      {Notifications, broadcast, ["#channel_id"]},
      refresh_interval: 60
    ]
})

```

Each `RssWatcher` worker takes a _url_, a _callback_, and
_configuration_. The `RssWatcher` handles a single RSS feed.
For multiple feeds, spawn additonal multiple `RssWatcher` processes.

### Url

The url should be a string, which resolves to an RSS feed.

### Callback

The callback can be in the form of `{module, function, arguments}`, or
an anonymous/suspended function.

If `{module, function, arguments}` format, the callback will be dispatched with
an additional argument - the parsed XML. Otherwise, the parsed XML will be
the only argument provided. See below for examples.

### Configuration

The third argument is a keyword list, configuring the `RssWatcher.Subscription`
that handles fetching and dispatching updates.

- `:refresh_interval` - integer. How often the feed is checked, in seconds. Defautls to `60`.
- `:rss_parser` - Atom/RSS 2.0 parser module. Defaults to `RssWatcher.Feed.Fiet`,
- `:rss_parser_options`- options for the above parser. Defaults to `[]`,
- `:http_client` - HTTP client for fetching updates. Defaults to `RssWatcher.HTTP.Tesla`,
- `:http_client_options` - options for the above client. Default to `[]`. See adapter module for configuration options.

### Examples

```elixir
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
```
