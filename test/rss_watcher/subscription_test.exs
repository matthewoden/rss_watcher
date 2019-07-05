defmodule RssWatcher.SubscriptionTest do
  use ExUnit.Case, async: true
  alias RssWatcher.{Subscription, Feed}

  def subscribe(port \\ "") do
    Subscription.new(
      "http://localhost:#{port}",
      fn update -> Process.send(self(), update, []) end,
      refresh_interval: 1
    )
  end

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  @moduletag :subscription

  test "new/3 creates a subscription" do
    subscription =
      Subscription.new("http://localhost", {Module, :atom, []},
        refresh_interval: 1,
        http_client_options: [test: true],
        http_client: Some.Module,
        rss_parser_options: [test: false],
        rss_parser: Some.Other.Module
      )

    assert subscription == %Subscription{
             refresh_interval: 1,
             http_client_options: [test: true],
             http_client: Some.Module,
             rss_parser_options: [test: false],
             rss_parser: Some.Other.Module,
             callback: {Module, :atom, []},
             pending_updates: [],
             recent_items: [],
             updated_at: subscription.updated_at,
             url: "http://localhost"
           }
  end

  test "Fetches and parses xml, fetching updates, and updating the seen cache", %{bypass: bypass} do
    timestamp = Utils.updated()

    Bypass.expect(bypass, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("atom/xml")
      |> Plug.Conn.resp(200, Utils.xml(timestamp))
    end)

    {:ok, subscription} = subscribe(bypass.port) |> Subscription.find_updates()

    assert subscription.pending_updates == [
             %Feed.Item{
               description: "Some text.",
               id: "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a",
               link: "http://example.org/2003/12/13/atom03",
               published_at: timestamp,
               title: "Atom-Powered Robots Run Amok"
             },
             %RssWatcher.Feed.Item{
               description: "Some text.",
               id: "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6b",
               link: "http://example.org/2003/12/13/atom04",
               published_at: NaiveDateTime.add(timestamp, 4, :second),
               title: "More Atom-Powered Robots Run Amok"
             }
           ]
  end

  test "updates the seen cache on fetch, and purging old ones", %{bypass: bypass} do
    timestamp = Utils.updated()

    Bypass.expect(bypass, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("atom/xml")
      |> Plug.Conn.resp(200, Utils.xml(timestamp))
    end)

    yesterday = NaiveDateTime.add(timestamp, -100_000, :second)

    {:ok, subscription} =
      subscribe(bypass.port)
      |> Map.put(:recent_items, [{yesterday, "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6c"}])
      |> Subscription.find_updates()

    assert subscription.recent_items == [
             {timestamp, "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a"},
             {NaiveDateTime.add(timestamp, 4, :second),
              "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6b"}
           ]
  end

  test "Dispatches updates only once, keeping a cache of seen ids or titles" do
    update = %Feed.Item{
      description: "Some text.",
      id: "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a",
      link: "http://example.org/2003/12/13/atom03",
      published_at: Utils.updated(),
      title: "Atom-Powered Robots Run Amok"
    }

    subscription =
      subscribe()
      |> Map.put(:pending_updates, [update])
      |> Subscription.dispatch_pending()

    assert_received update
    assert subscription.pending_updates == []
  end
end
