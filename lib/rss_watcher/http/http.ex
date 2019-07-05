defmodule RssWatcher.HTTP do
  @moduledoc """
  HTTP adapter spec. Takes a url, and returns either unparsed xml, or an error.
  """
  @type url :: String.t()

  @doc """
  Given a url, the adapter should fetch the feed, confirm that it's xml, and
  return the unparsed xml data.
  """
  @callback get_feed(url) ::
              {:ok, String.t()}
              | {:error, {:http_client_error, term}}
              | {:error, {:not_xml, String.t()}}
              | {:error, {:unsuccessful_request, term}}
end
