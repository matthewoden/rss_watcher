defmodule RssWatcher.Feed.Item do
  @moduledoc """
  An item within a `RssWatcher.Feed`.
  """
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
