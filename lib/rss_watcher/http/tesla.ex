if Code.ensure_loaded?(Tesla) do
  defmodule RssWatcher.HTTP.Adapter.Tesla do
    @moduledoc """
    Tesla-based adapter for http fetching. Used by default in subscriptions.

    ## Installation

    To use, add the following to your dependancies.
    ```
        {:tesla, "~> 1.2.1"}
    ```
    You may need to add additional dependencies based on your http adapter
    of choice.

    Additional middleware and adapter configuration can be provided through
    the `http_client_options` key in the `RssWatcher.Subscription` config.

    ## Options
    - `:adapter` - The tesla adpater to use
    - `:middleware - The tesla middleware to use
    """
    require Logger

    @behaviour RssWatcher.HTTP.Adapter

    @spec get_feed(String.t(), Keyword.t()) ::
            {:ok, String.t()}
            | {:error, {:http_client_error, term}}
            | {:error, {:not_xml, String.t()}}
            | {:error, {:unsuccessful_request, term}}

    def get_feed(url, options \\ []) do
      with {:ok, %Tesla.Env{status: status, headers: headers, body: body}}
           when status == 200 <- Tesla.get(client(options), url),
           {true, _content_type} <- is_xml(headers) do
        {:ok, body}
      else
        {false, content_type} ->
          {:error, {:not_xml, content_type}}

        {:ok, response} ->
          {:error, {:unsuccessful_request, response}}

        {:error, reason} ->
          {:error, {:http_client_error, reason}}
      end
    end

    defp client(options) do
      base_middleware = [
        {Tesla.Middleware.Timeout, timeout: 10_000},
        Tesla.Middleware.FollowRedirects,
        {Tesla.Middleware.Retry, delay: 500, max_retries: 10},
        {Tesla.Middleware.Headers, [{"user-agent", "Elixir/RssWatcher"}]}
      ]

      middleware = Keyword.get(options, :middleware, [])
      adapter = Keyword.get(options, :adapter, Tesla.Adapter.Httpc)
      Tesla.client(base_middleware ++ middleware, adapter)
    end

    defp is_xml(headers) do
      case Enum.find(headers, fn {header, _val} -> "content-type" == header end) do
        {_, val} ->
          # too many MIME types for xml
          {String.contains?(val, "xml"), val}

        nil ->
          {false, ""}
      end
    end
  end
end
