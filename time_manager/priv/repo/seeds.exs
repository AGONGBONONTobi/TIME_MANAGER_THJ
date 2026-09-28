import Ecto.Query

alias TimeManager.Accounts.User
alias TimeManager.Clocking.Clock
alias TimeManager.Repo
alias TimeManager.WorkingTimes.WorkingTime

user =
  case Repo.get_by(User, email: "joseph.william@example.com") do
    nil ->
      %User{}
      |> User.changeset(%{username: "Joseph William", email: "joseph.william@example.com"})
      |> Repo.insert!()

    existing ->
      existing
  end

Repo.delete_all(from clock in Clock, where: clock.user_id == ^user.id)
Repo.delete_all(from working_time in WorkingTime, where: working_time.user_id == ^user.id)

today = Date.utc_today()
at = fn date, hour, minute -> DateTime.new!(date, Time.new!(hour, minute, 0), "Etc/UTC") end

sessions =
  0..45
  |> Enum.flat_map(fn offset ->
    date = Date.add(today, -offset)

    if Date.day_of_week(date) <= 5 do
      case {offset, rem(offset, 7)} do
        {0, _} ->
          morning_start = at.(date, 8, 30)
          afternoon_start = at.(date, 13, 0)
          evening_start = at.(date, 15, 30)

          [
            {date, morning_start, at.(date, 12, 0), :day},
            {date, afternoon_start, at.(date, 15, 0), :day},
            {date, evening_start, at.(date, 17, 30), :day}
          ]

        {_, 0} ->
          start_time = at.(date, 21, 0)
          [{date, start_time, DateTime.add(start_time, 5 * 60 * 60, :second), :night}]

        3 ->
          start_time = at.(date, 8, 45)
          [{date, start_time, DateTime.add(start_time, 7 * 60 * 60 + 30 * 60, :second), :day}]

        _ ->
          start_time = at.(date, 9, 0)
          [{date, start_time, DateTime.add(start_time, 8 * 60 * 60, :second), :day}]
      end
    else
      []
    end
  end)

Enum.each(sessions, fn {_date, start_time, end_time, _type} ->
  Repo.insert!(%WorkingTime{user_id: user.id, start: start_time, end: end_time})

  Repo.insert!(%Clock{user_id: user.id, time: start_time, status: true})
  Repo.insert!(%Clock{user_id: user.id, time: end_time, status: false})
end)

IO.puts("Seeded Joseph William (user ##{user.id}) with #{length(sessions)} working sessions.")
