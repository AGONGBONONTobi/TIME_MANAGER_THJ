defmodule TimeManager.WorkingTimesTest do
  use TimeManager.DataCase

  alias TimeManager.Accounts
  alias TimeManager.WorkingTimes

  test "creates and lists a working time for a user" do
    {:ok, user} = Accounts.create_user(%{username: "working-user", email: "working@example.com"})

    assert {:ok, working_time} =
             WorkingTimes.create_for_user(user.id, %{
               "start" => "2026-09-20T13:09:00Z",
               "end" => "2026-09-20T17:09:00Z"
             })

    assert [^working_time] = WorkingTimes.list_for_user(user.id)
  end

  test "rejects a working time without a start" do
    {:ok, user} = Accounts.create_user(%{username: "working-user", email: "working@example.com"})

    assert {:error, changeset} =
             WorkingTimes.create_for_user(user.id, %{"end" => "2026-09-20T17:09:00Z"})

    assert %{start: ["can't be blank"]} = errors_on(changeset)
  end
end
