defmodule RssWatcher.HTTP.TeslaTest do
  alias RssWatcher.HTTP.Tesla, as: HTTP
  use ExUnit.Case, async: true

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "successful call that returns xml returns the xml", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("atom/xml")
      |> Plug.Conn.resp(200, "<xml/>")
    end)

    assert {:ok, "<xml/>"} = HTTP.get_feed("http://localhost:#{bypass.port}")
  end

  test "non-200 call returns an error", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("atom/xml")
      |> Plug.Conn.resp(404, "<not-found/>")
    end)

    assert {:error, {:unsuccessful_request, _}} = HTTP.get_feed("http://localhost:#{bypass.port}")
  end

  test "200 call returns something other than xml", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, ~s<{"ok": true}>)
    end)

    assert {:error, {:not_xml, _}} = HTTP.get_feed("http://localhost:#{bypass.port}")
  end
end
