defmodule TimeManager.ClockingTest do
  use TimeManager.DataCase

  alias TimeManager.Accounts
  alias TimeManager.Clocking
  alias TimeManager.WorkingTimes

  test "arrival creates a true clock and an open working time" do
    {:ok, user} = Accounts.create_user(%{username: "clock-user", email: "clock@example.com"})

    assert {:ok, clock} = Clocking.create_clock(user.id)
    assert clock.status

    working_time = WorkingTimes.open_session(user.id)
    assert working_time.user_id == user.id
    assert working_time.start == clock.time
    assert is_nil(working_time.end)
  end

  test "departure creates a false clock and closes the working time" do
    {:ok, user} = Accounts.create_user(%{username: "clock-user", email: "clock@example.com"})
    assert {:ok, arrival} = Clocking.create_clock(user.id)
    assert {:ok, departure} = Clocking.create_clock(user.id)

    refute departure.status
    assert WorkingTimes.open_session(user.id) == nil
    [working_time] = WorkingTimes.list_for_user(user.id)
    assert working_time.start == arrival.time
    assert working_time.end == departure.time
  end

  test "an unknown user cannot create a clock" do
    assert {:error, :user_not_found} = Clocking.create_clock(999_999)
  end
end
