defmodule MyectoTest do
  use ExUnit.Case
  doctest Myecto

  test "greets the world" do
    assert Myecto.hello() == :world
  end
end
