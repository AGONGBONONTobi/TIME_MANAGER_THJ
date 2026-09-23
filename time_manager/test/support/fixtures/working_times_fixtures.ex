defmodule TimeManager.WorkingTimesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TimeManager.WorkingTimes` context.
  """

  @doc """
  Generate a working_time.
  """
  def working_time_fixture(attrs \\ %{}) do
    {:ok, user} =
      TimeManager.Accounts.create_user(%{
        username: "working-fixture-#{System.unique_integer([:positive])}",
        email: "working-fixture-#{System.unique_integer([:positive])}@example.com"
      })

    {:ok, working_time} =
      attrs
      |> Enum.into(%{
        end: ~U[2026-09-20 13:09:00Z],
        start: ~U[2026-09-20 12:09:00Z],
        user_id: user.id
      })
      |> TimeManager.WorkingTimes.create_working_time()

    working_time
  end
end
