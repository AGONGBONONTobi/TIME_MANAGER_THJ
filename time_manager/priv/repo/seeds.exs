alias TimeManager.Repo
alias TimeManager.Accounts.User
alias TimeManager.Teams.Team
alias TimeManager.Teams.TeamMembership
alias TimeManager.Clocking.Clock
alias TimeManager.WorkingTimes.WorkingTime

# Clean the database
Repo.delete_all(WorkingTime)
Repo.delete_all(Clock)
Repo.delete_all(TeamMembership)
Repo.delete_all(Team)
Repo.delete_all(User)

now = DateTime.utc_now() |> DateTime.truncate(:second)

# Insert Admin
{:ok, admin} = Repo.insert(%User{
  username: "Admin Gotham",
  email: "admin@example.com",
  password_hash: Bcrypt.hash_pwd_salt("password123"),
  role: "admin",
  status: "active"
})

# Insert 15 Managers and 300 Employees (Total 316 users)
managers =
  for i <- 1..15 do
    {:ok, manager} = Repo.insert(%User{
      username: "Manager #{i}",
      email: "manager#{i}@example.com",
      password_hash: Bcrypt.hash_pwd_salt("password123"),
      role: "manager",
      status: "active"
    })
    manager
  end

teams =
  for {manager, idx} <- Enum.with_index(managers) do
    {:ok, team} = Repo.insert(%Team{
      name: "Team #{idx + 1}",
      manager_id: manager.id
    })
    team
  end

employees =
  for i <- 1..300 do
    {:ok, employee} = Repo.insert(%User{
      username: "Employee #{i}",
      email: "employee#{i}@example.com",
      password_hash: Bcrypt.hash_pwd_salt("password123"),
      role: "employee",
      status: "active",
      contract_start: ~D[2023-01-01]
    })
    
    # Assign to a random team (roughly 20 per team)
    team = Enum.at(teams, rem(i, 15))
    Repo.insert!(%TeamMembership{team_id: team.id, user_id: employee.id, active: true})
    
    employee
  end

IO.puts("Seeding clocks and working times for 300 employees...")
for employee <- employees do
  for days_ago <- 7..1 do
    start_time = DateTime.add(now, -days_ago * 86400, :second) |> %{now | hour: 9, minute: 0, second: 0}
    end_time = DateTime.add(now, -days_ago * 86400, :second) |> %{now | hour: 17, minute: 0, second: 0}
    
    # 10% chance to miss a clock out
    is_missed = Enum.random(1..10) == 1

    if not is_missed do
      Repo.insert!(%WorkingTime{user_id: employee.id, start: start_time, end: end_time})
      Repo.insert!(%Clock{user_id: employee.id, time: start_time, status: true})
      Repo.insert!(%Clock{user_id: employee.id, time: end_time, status: false})
    else
      Repo.insert!(%Clock{user_id: employee.id, time: start_time, status: true})
    end
  end
end

IO.puts("✅ Database successfully seeded with 316 users (1 Admin, 15 Managers, 300 Employees)!")
