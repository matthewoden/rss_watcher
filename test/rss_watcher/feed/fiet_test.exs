defmodule RssWatcher.Feed.Adapter.FietTest do
  use ExUnit.Case, async: true
  alias RssWatcher.Feed.Adapter.Fiet

  test "it parses RSS 2.0 XML" do
    {:ok, parsed} = File.read!("./test/data/Rss2.xml") |> Fiet.parse_feed([])

    assert %RssWatcher.Feed{
             link: "http://www.scripting.com/",
             title: "Scripting News",
             description: "A weblog about scripting and stuff like that.",
             categories: []
           } = parsed

    item = Enum.at(parsed.items, 6)

    assert %RssWatcher.Feed.Item{
             description:
               "<p><a href=\"http://www.nbc.com/Law_&_Order/index.html\"><img src=\"http://radio.weblogs.com/0001015/images/2002/09/29/lenny.gif\" width=\"45\" height=\"53\" border=\"0\" align=\"right\" hspace=\"15\" vspace=\"5\" alt=\"A picture named lenny.gif\"></a>A great line in a recent Law and Order. Lenny Briscoe, played by Jerry Orbach, is interrogating a suspect. The suspect tells a story and reaches a point where no one believes him, not even the suspect himself. Lenny says: \"Now there's five minutes of my life that's lost forever.\" </p>",
             id: "http://scriptingnews.userland.com/backissues/2002/09/29#lawAndOrder",
             link: "http://scriptingnews.userland.com/backissues/2002/09/29#lawAndOrder",
             title: "Law and Order"
           } = item
  end

  test "it parses Atom XML" do
    {:ok, parsed} = File.read!("./test/data/atom.xml") |> Fiet.parse_feed([])

    assert %RssWatcher.Feed{
             link: "http://example.org/",
             title: "Example Feed",
             description: nil,
             categories: [],
             items: [
               %RssWatcher.Feed.Item{
                 description: "Some text.",
                 id: "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a",
                 link: "http://example.org/2003/12/13/atom03",
                 title: "Atom-Powered Robots Run Amok"
               }
             ]
           } = parsed
  end
end
