defmodule RssWatcher.HTTP.Adapter do
  @moduledoc """
  HTTP adapter spec. Takes a url, and returns either unparsed xml, or an error.
  """
  @type url :: String.t()

  @callback get_feed(url) ::
              {:ok, String.t()}
              | {:error, {:http_client_error, term}}
              | {:error, {:not_xml, String.t()}}
              | {:error, {:unsuccessful_request, term}}
end
