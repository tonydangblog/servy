defmodule PledgeServerTest do
  use ExUnit.Case

  alias Servy.PledgeServer

  test "caches only the 3 most recent pledges" do
    # GIVEN server and 5 pledges
    PledgeServer.start()
    PledgeServer.create_pledge("larry", 10)
    PledgeServer.create_pledge("moe", 20)
    PledgeServer.create_pledge("curly", 30)
    PledgeServer.create_pledge("daisy", 40)
    PledgeServer.create_pledge("grace", 50)

    # WHEN most recent pledges & total are requested
    pledges = PledgeServer.recent_pledges()
    total = PledgeServer.total_pledged()

    # THEN only most three recent pledged are cached and totaled
    assert pledges == [{"grace", 50}, {"daisy", 40}, {"curly", 30}]
    assert total == 120
  end
end
