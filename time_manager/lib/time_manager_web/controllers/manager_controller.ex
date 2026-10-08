defmodule TimeManagerWeb.ManagerController do
  use TimeManagerWeb, :controller

  alias TimeManager.Accounts
  alias TimeManager.Teams
  alias TimeManager.WorkingTimes
  alias TimeManager.Clocking
  alias TimeManager.Notifications

  def team(conn, _params) do
    now = DateTime.utc_now()
    week_start = DateTime.add(now, -7 * 24 * 60 * 60, :second)

    employees =
      team_users(conn)
      |> Enum.map(&team_member(&1, week_start, now))

    json(conn, %{data: employees})
  end

  # POST /api/manager/teams/:team_id/clock — pointer toute l'équipe
  def team_clock(conn, %{"team_id" => team_id}) do
    team = Teams.get_team(team_id)

    if is_nil(team) do
      send_resp(conn, :not_found, "")
    else
      user_ids =
        team.memberships
        |> Enum.map(& &1.user_id)

      results =
        Enum.map(user_ids, fn uid ->
          case Clocking.create_clock(uid) do
            {:ok, clock} -> %{user_id: uid, status: clock.status, time: clock.time}
            {:error, reason} -> %{user_id: uid, error: inspect(reason)}
          end
        end)

      json(conn, %{data: results})
    end
  end

  # GET /api/manager/users/:userID/payroll — résumé paie
  def payroll_summary(conn, %{"userID" => user_id}) do
    now = DateTime.utc_now()
    week_start = DateTime.add(now, -7 * 24 * 60 * 60, :second)

    working_times = WorkingTimes.list_for_user(user_id)
    weekly_times = Enum.filter(working_times, &(DateTime.compare(&1.start, week_start) != :lt))
    completed = Enum.filter(weekly_times, & &1.end)

    total_seconds = Enum.reduce(completed, 0, fn wt, acc ->
      acc + DateTime.diff(wt.end, wt.start, :second)
    end)

    night_seconds = Enum.reduce(completed, 0, fn wt, acc ->
      acc + night_seconds_for(wt)
    end)

    normal_seconds = total_seconds - night_seconds

    total_hours = total_seconds / 3600.0
    overtime_hours = max(total_hours - 40.0, 0.0)
    regular_hours = min(total_hours, 40.0) - night_seconds / 3600.0
    night_hours = night_seconds / 3600.0

    json(conn, %{
      data: %{
        user_id: user_id,
        total_hours: Float.round(total_hours, 2),
        regular_hours: Float.round(max(regular_hours, 0.0), 2),
        night_hours: Float.round(night_hours, 2),
        overtime_hours: Float.round(overtime_hours, 2),
        regular_pay_rate: 1.0,
        night_pay_rate: 1.5,
        overtime_pay_rate: 2.0
      }
    })
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

  # Calcul des secondes de nuit (22h–6h) pour une session
  defp night_seconds_for(%{start: s, end: e}) when not is_nil(e) do
    # Interval de 22h à 6h du lendemain
    night_start_hour = 22
    night_end_hour = 6

    total_secs = DateTime.diff(e, s, :second)
    if total_secs <= 0 do
      0
    else
      # Parcourir heure par heure est trop lourd; on utilise une approche par tranches
      count_night_seconds(s, e, night_start_hour, night_end_hour)
    end
  end
  defp night_seconds_for(_), do: 0

  defp count_night_seconds(s, e, night_h_start, night_h_end) do
    # On itère par intervalles de 1 minute pour précision raisonnable
    # Simplifié : on compte chaque heure entière chevauchée
    Stream.iterate(s, &DateTime.add(&1, 3600, :second))
    |> Stream.take_while(&(DateTime.compare(&1, e) == :lt))
    |> Enum.reduce(0, fn hour_start, acc ->
      hour_end = DateTime.add(hour_start, 3600, :second)
      segment_end = if DateTime.compare(hour_end, e) == :gt, do: e, else: hour_end
      seconds_in_segment = DateTime.diff(segment_end, hour_start, :second)
      h = hour_start.hour
      if h >= night_h_start or h < night_h_end do
        acc + seconds_in_segment
      else
        acc
      end
    end)
  end
end
