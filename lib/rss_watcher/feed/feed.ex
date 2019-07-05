defmodule RssWatcher.Feed.Item do
  @moduledoc """
  Normalized item/entity within a `RssWatcher.Feed`.
  """
  @moduledoc since: "0.1.0"
  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          description: String.t(),
          published_at: NaiveDateTime.t() | DateTime.t(),
          link: String.t()
        }

  defstruct [
    :id,
    :title,
    :description,
    :published_at,
    :link
  ]
end

defmodule RssWatcher.Feed do
  @moduledoc """
  A `RssWatcher.Feed` is a parsed RSS feed, containing a list of `RssWatcher.Feed.Item`

  ## Writing parsers
  The goal of RssWatcher is to dispatch updates for individual items.
  Should an item have an invalid entity, or a timestamp that cannot be parsed, we ignore it
  and move on.

  ### Time
  Parsers need to handle both XML parsing, and timestamp parsing.

  #### Formats:
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
  @moduledoc since: "0.1.0"

  @type xml :: String.t()
  @type options :: Keyword.t()

  alias RssWatcher.{Feed}
  alias Feed.Item

  @type t :: %__MODULE__{
          title: String.t(),
          link: String.t(),
          description: String.t(),
          updated_at: NaiveDateTime.t() | DateTime.t(),
          categories: list(String.t()),
          items: list(Item.t())
        }

  defstruct [
    :title,
    :link,
    :description,
    :updated_at,
    categories: [],
    items: []
  ]

  @doc """
  Parse a string of XML.
  """
  @doc since: "0.1.0"
  @callback parse_feed(String.t(), Keyword.t()) :: {:ok, Feed.t()} | {:error, term}
end
