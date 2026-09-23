defmodule TimeManager.ClockingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TimeManager.Clocking` context.
  """

  @doc """
  Generate a clock.
  """
  def clock_fixture(attrs \\ %{}) do
    {:ok, user} =
      TimeManager.Accounts.create_user(%{
        username: "clock-fixture-#{System.unique_integer([:positive])}",
        email: "clock-fixture-#{System.unique_integer([:positive])}@example.com"
      })

    {:ok, _arrival} = TimeManager.Clocking.create_clock(user.id)
    {:ok, clock} = TimeManager.Clocking.create_clock(user.id)

    clock = %{
      clock
      | status: Map.get(attrs, :status, clock.status),
        time: Map.get(attrs, :time, clock.time)
    }

    clock
  end
end
