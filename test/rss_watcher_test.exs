defmodule RssWatcherTest do
  alias RssWatcher.Subscription
  use ExUnit.Case, async: true

  setup do
    bypass = Bypass.open()
    timestamp = Utils.updated()

    Bypass.expect(bypass, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("atom/xml")
      |> Plug.Conn.resp(200, Utils.xml(timestamp))
    end)

    subscription =
      Subscription.new(
        "http://localhost:#{bypass.port}",
        &Process.send(self(), &1, []),
        []
      )

    {:ok, bypass: bypass, subscription: subscription}
  end

  test "loop callback fetches/dispatches updates", %{subscription: subscription} do
    {:noreply, _state} = RssWatcher.handle_info(:poll, %{subscription: subscription})
    assert_received update
  end

  test "loop callback clears any pending updates", %{subscription: subscription} do
    {:noreply, %{subscription: subscription}} =
      RssWatcher.handle_info(:poll, %{subscription: subscription})

    assert subscription.pending_updates == []
  end

  test "loop schedules a new loop", %{bypass: bypass} do
    subscription =
      Subscription.new(
        "http://localhost:#{bypass.port}",
        &Process.send(self(), &1, []),
        refresh_interval: 0
      )

    {:noreply, _} = RssWatcher.handle_info(:poll, %{subscription: subscription})
    Process.sleep(1)
    assert_received :poll
  end
end
