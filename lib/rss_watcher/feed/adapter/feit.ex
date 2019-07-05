if Code.ensure_loaded?(Fiet) and Code.ensure_loaded?(Timex) do
  defmodule RssWatcher.Feed.Fiet do
    @moduledoc """
    A Fiet + Timex based RSS parser. Used by default in subscriptions.

    Add the following to your dependancies:
    ```
        {:fiet, "~> 0.2.1"},
        {:timex, "~> 3.0"}
    ```

    And add `:timex` to your list of extra_applications.
    """
    @moduledoc since: "0.1.0"

    alias RssWatcher.Feed
    require Logger

    @behaviour RssWatcher.Feed

    @impl true
    @spec parse_feed(String.t(), Keyword.t()) :: {:error, any} | {:ok, RssWatcher.Feed.t()}
    def parse_feed(xml, _) do
      with {:ok, parsed} <- Fiet.parse(xml),
           {:ok, updated_at} <- parse_timestamp(parsed.updated_at) do
        items =
          parsed.items
          |> Enum.map(&parse_item/1)
          |> Enum.filter(& &1)

        {:ok,
         %Feed{
           title: trim(parsed.title),
           link: parsed.link,
           description: trim(parsed.description),
           updated_at: updated_at,
           items: items
         }}
      else
        {:error, _reason} = otherwise -> otherwise
      end
    end

    defp parse_item(item) do
      with {:ok, published_at} <- parse_timestamp(item.published_at) do
        %Feed.Item{
          id: item.id,
          title: trim(item.title),
          description: trim(item.description),
          published_at: published_at,
          link: item.link
        }
      else
        _ ->
          Logger.warn("Invalid timestamp for feed item: #{item.published_at}")
          nil
      end
    end

    def trim(nil), do: nil
    def trim(string) when is_binary(string), do: String.trim(string)

    @timestamp_formats [
      "{RFC822}",
      "{RFC822z}",
      "{RFC1123}",
      "{RFC1123z}",
      "{RFC3339}",
      "{RFC3339z}"
    ]

    defp parse_timestamp(nil), do: {:error, :no_timestamp}

    defp parse_timestamp(timestamp), do: try_parse_timestamp(timestamp, @timestamp_formats)

    defp try_parse_timestamp(timestamp, []),
      do: {:error, "Unknown format for timestamp #{timestamp}."}

    defp try_parse_timestamp(timestamp, [format | rest]) do
      case Timex.parse(timestamp, format) do
        {:ok, _result} = outcome -> outcome
        _ -> try_parse_timestamp(timestamp, rest)
      end
    end
  end
end
