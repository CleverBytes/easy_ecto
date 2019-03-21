defmodule EASYTest do
  use ExUnit.Case
  doctest EASY

  test "greets the world" do
    assert EASY.hello() == :world
  end
end
