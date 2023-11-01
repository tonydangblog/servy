defmodule HttpServerTest do
  use ExUnit.Case

  @test_port 4321

  test "test request to server" do
    # GIVEN
    spawn(Servy.HttpServer, :start, [@test_port])

    urls = [
      "http://localhost:#{@test_port}/wildthings",
      "http://localhost:#{@test_port}/bears",
      "http://localhost:#{@test_port}/bears/1",
      "http://localhost:#{@test_port}/wildlife",
      "http://localhost:#{@test_port}/api/bears"
    ]

    # WHEN...THEN
    urls
    |> Enum.map(&Task.async(fn -> HTTPoison.get(&1) end))
    |> Enum.map(&Task.await/1)
    |> Enum.each(fn {:ok, res} -> assert res.status_code == 200 end)
  end
end
