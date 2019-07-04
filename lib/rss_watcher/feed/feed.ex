defmodule RssWatcher.Feed do
  @moduledoc """
  Normlized RSS/Atom Feed
  """
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
end
