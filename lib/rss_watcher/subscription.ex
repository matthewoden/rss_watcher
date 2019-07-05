defmodule RssWatcher.Subscription do
  require Logger
  alias RssWatcher

  @moduledoc """
  The logical
  A `RssWatcher.Subscription` fetches, parses, and dispatches updates for RSS
  feeds.

  This module should not be used directly, and instead rely on `RssWatcher`
  configuration for initialization and use.
  """

  defstruct url: nil,
            refresh_interval: 60,
            updated_at: nil,
            recent_titles: [],
            pending_updates: [],
            rss_parser: RssWatcher.Feed.Fiet,
            rss_parser_options: [],
            http_client: RssWatcher.HTTP.Tesla,
            http_client_options: [],
            callback: nil

  @type recent_title :: {NaiveDateTime.t() | DateTime.t(), String.t()}
  @type callback :: fun() | {module, atom, list}
  @type options :: Keyword.t()
  @type t :: %__MODULE__{
          url: String.t(),
          refresh_interval: integer,
          updated_at: NaiveDateTime.t() | DateTime.t(),
          recent_titles: [recent_title],
          pending_updates: list,
          rss_parser: module,
          rss_parser_options: [],
          http_client: module,
          http_client_options: [],
          callback: callback
        }

  @doc """
  Generates a new subscription
  """
  @spec new(String.t(), callback, options) :: t
  def new(url, fun, opts \\ []) do
    {refresh_interval, opts} = Keyword.pop(opts, :refresh_interval, 60)
    {rss_parser, opts} = Keyword.pop(opts, :rss_parser, RssWatcher.Feed.Fiet)
    {rss_parser_options, opts} = Keyword.pop(opts, :rss_parser_options, [])
    {http_client, opts} = Keyword.pop(opts, :http_client, RssWatcher.HTTP.Tesla)
    {http_client_options, _opts} = Keyword.pop(opts, :http_client_options, [])

    struct(__MODULE__,
      url: url,
      callback: fun,
      refresh_interval: refresh_interval,
      http_client: http_client,
      http_client_options: http_client_options,
      rss_parser: rss_parser,
      rss_parser_options: rss_parser_options,
      updated_at: NaiveDateTime.utc_now()
    )
  end

  @doc """
  Finds updated items for a subscription, and stores them as pending updates.
  """
  @spec find_updates(t) :: {:ok, t} | {:error, term}
  def find_updates(%__MODULE__{} = subscription) do
    with {:ok, xml} <- get_feed(subscription),
         {:ok, parsed} <- parse_feed(subscription, xml),
         true <- fresh?(subscription.updated_at, parsed.updated_at) do
      pending_updates = Enum.filter(parsed.items, fn item -> fresh_item?(subscription, item) end)

      subscription = %{
        subscription
        | pending_updates: pending_updates,
          recent_titles: update_titles(subscription.recent_titles, pending_updates),
          updated_at: now()
      }

      {:ok, subscription}
    else
      false ->
        {:ok, subscription}

      {:error, _reason} = otherwise ->
        otherwise
    end
  end

  defp get_feed(%__MODULE__{url: url, http_client: client, http_client_options: options}),
    do: client.get_feed(url, options)

  defp parse_feed(%__MODULE__{rss_parser: parser, rss_parser_options: options}, xml),
    do: parser.parse_feed(xml, options)

  @doc """
  Dispatches all pending updates for a subscription.
  """
  @spec dispatch_pending(t) :: t
  def dispatch_pending(subscription) do
    Enum.each(subscription.pending_updates, fn update ->
      try do
        dispatch(subscription.callback, update)
      catch
        kind, reason ->
          formatted = Exception.format(kind, reason, __STACKTRACE__)
          Logger.error("dispatch/2 failed with #{formatted}")
      end
    end)

    %{subscription | pending_updates: []}
  end

  defp yesterday, do: DateTime.utc_now() |> DateTime.add(-86400, :second)

  defp now(), do: DateTime.utc_now()

  defp fresh?(seen, new) do
    case NaiveDateTime.compare(seen, new) do
      :gt -> false
      :lt -> true
    end
  end

  defp fresh_item?(subscription, item) do
    fresh = fresh?(subscription.updated_at, item.published_at)

    sneaky_title = Enum.any?(subscription.recent_titles, fn {_, title} -> title == item.title end)

    fresh and not sneaky_title
  end

  defp update_titles(titles, updates) do
    updates
    |> Enum.map(fn %{title: title, published_at: published_at} -> {published_at, title} end)
    |> Enum.concat(titles)
    |> Enum.filter(fn {date, _} -> fresh?(date, yesterday()) end)
  end

  defp dispatch({m, f, a}, update), do: apply(m, f, a ++ [update])
  defp dispatch(fun, update) when is_function(fun), do: apply(fun, [update])
end
