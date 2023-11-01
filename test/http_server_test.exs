defmodule HttpServerTest do
  use ExUnit.Case

  @test_port 4321

  test "test request to server" do
    # GIVEN
    spawn(Servy.HttpServer, :start, [@test_port])
    url = "http://localhost:#{@test_port}/wildthings"

    # WHEN...THEN
    1..5
    |> Enum.map(fn _ -> Task.async(fn -> HTTPoison.get(url) end) end)
    |> Enum.map(&Task.await/1)
    |> Enum.each(fn {:ok, res} ->
      assert res.status_code == 200
      assert res.body == "Bears, Lions, Tigers"
    end)
  end
end
