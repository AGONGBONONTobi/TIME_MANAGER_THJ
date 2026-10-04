defmodule TimeManagerWeb.ManagerController do
  use TimeManagerWeb, :controller

  alias TimeManager.Accounts
  alias TimeManager.Teams
  alias TimeManager.WorkingTimes
  alias TimeManager.Notifications

  def team(conn, _params) do
    now = DateTime.utc_now()
    week_start = DateTime.add(now, -7 * 24 * 60 * 60, :second)

    employees =
      team_users(conn)
      |> Enum.map(&team_member(&1, week_start, now))

    json(conn, %{data: employees})
  end

  defp team_users(conn) do
    if conn.assigns.current_user.role == "admin" do
      Accounts.list_users() |> Enum.reject(&(&1.role == "admin"))
    else
      Teams.list_teams()
      |> Enum.filter(&(&1.manager_id == conn.assigns.current_user.id))
      |> Enum.flat_map(& &1.memberships)
      |> Enum.map(& &1.user)
      |> Enum.uniq_by(& &1.id)
    end
  end

  def remind(conn, %{"userID" => user_id}) do
    case Notifications.remind_about_clock(user_id, conn.assigns.current_user.id) do
      {:ok, notification} ->
        conn
        |> put_status(:created)
        |> json(%{
          data: %{id: notification.id, user_id: notification.user_id, type: notification.type}
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: "Reminder could not be created",
          details: Ecto.Changeset.traverse_errors(changeset, fn {message, _} -> message end)
        })
    end
  end

  defp team_member(user, week_start, now) do
    working_times = WorkingTimes.list_for_user(user.id)
    weekly_times = Enum.filter(working_times, &(DateTime.compare(&1.start, week_start) != :lt))
    completed_times = Enum.filter(weekly_times, & &1.end)

    %{
      id: user.id,
      name: user.username,
      email: user.email,
      role: user.role,
      hours: Enum.reduce(completed_times, 0.0, &hours_for(&1, &2, now)),
      nights: Enum.count(weekly_times, &night_shift?/1),
      validated: Enum.all?(weekly_times, & &1.end),
      missedClock: Enum.any?(weekly_times, &is_nil(&1.end))
    }
  end

  defp hours_for(working_time, total, now) do
    finish = working_time.end || now
    total + DateTime.diff(finish, working_time.start, :second) / 3600
  end

  defp night_shift?(working_time) do
    hour = working_time.start.hour
    hour >= 22 or hour < 6
  end
end
