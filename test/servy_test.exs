defmodule ServyTest do
  use ExUnit.Case
  doctest Servy

  test "greets the world" do
    assert Servy.hello("Tony") == "Howdy, Tony"
  end
end
