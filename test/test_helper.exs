ExUnit.start()
Application.ensure_all_started(:bypass)
Application.ensure_all_started(:timex)

defmodule Utils do
  def updated do
    NaiveDateTime.utc_now() |> NaiveDateTime.add(100, :second)
  end

  def xml(updated) do
    """
    <?xml version="1.0" encoding="utf-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">

      <title>Example Feed</title>
      <link href="http://example.org/"/>
      <updated>#{NaiveDateTime.to_string(updated)}</updated>
      <author>
        <name>John Doe</name>
      </author>
      <id>urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6</id>

      <entry>
        <title>Atom-Powered Robots Run Amok</title>
        <link href="http://example.org/2003/12/13/atom03"/>
        <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
        <updated>#{NaiveDateTime.to_string(updated)}</updated>
        <summary>Some text.</summary>
      </entry>
      <entry>
        <title>More Atom-Powered Robots Run Amok</title>
        <link href="http://example.org/2003/12/13/atom04"/>
        <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6b</id>
        <updated>#{NaiveDateTime.add(updated, 4, :second) |> NaiveDateTime.to_string()}</updated>
        <summary>Some text.</summary>
      </entry>

    </feed>
    """
  end
end
