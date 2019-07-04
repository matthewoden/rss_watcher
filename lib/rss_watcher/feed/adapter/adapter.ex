defmodule RssWatcher.Feed.Adapter do
  @moduledoc """
  Adapter spec for parsing of RSS feeds.

  A parser will need to handle parsing timestamps, in addition to XML/Atom/RSS2

  ## Time Formats:
  RSS 2.0 feeds should follow RFC 822, e.g. `Sat, 07 Sep 02 00:00:01 GMT`
  but also allows for a four digit year, `Sat, 07 Sep 2002 00:00:01 GMT`
  which is actually handled by RFC1123.

  Atom feeds should follow RFC3339, e.g. `2005-07-31T12:29:29Z`

  Which means formats can be any of the following, with or without timezone
  information:

  - RFC822
  - RFC1123
  - RFC3339
  """

  @type xml :: String.t()
  @type options :: Keyword.t()

  @callback parse_feed(String.t(), Keyword.t()) :: {:ok, Feed.t()} | {:error, term}
end
