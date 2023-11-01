defmodule HttpServerTest do
  use ExUnit.Case

  @test_port 4321

  test "test request to server" do
    # GIVEN
    parent = self()
    spawn(Servy.HttpServer, :start, [@test_port])

    # WHEN
    num_concurrent_requests = 5

    for _ <- 1..num_concurrent_requests do
      spawn(fn -> send(parent, HTTPoison.get("http://localhost:#{@test_port}/wildthings")) end)
    end

    # THEN
    for _ <- 1..num_concurrent_requests do
      receive do
        {:ok, res} ->
          assert res.status_code == 200
          assert res.body == "Bears, Lions, Tigers"
      end
    end
  end
end
