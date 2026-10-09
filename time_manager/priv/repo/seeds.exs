alias TimeManager.Repo
alias TimeManager.Accounts.User
alias TimeManager.Organization.Team
alias TimeManager.Organization.TeamUser
alias TimeManager.Clocking.Clock
alias TimeManager.WorkingTimes.WorkingTime

# Clean the database
Repo.delete_all(WorkingTime)
Repo.delete_all(Clock)
Repo.delete_all(TeamUser)
Repo.delete_all(Team)
Repo.delete_all(User)

# Insert Users
{:ok, admin} = Repo.insert(%User{
  username: "Admin Gotham",
  email: "admin@example.com",
  password_hash: Bcrypt.hash_pwd_salt("password123"),
  role: "admin",
  status: "active"
})

{:ok, manager_bruce} = Repo.insert(%User{
  username: "Bruce Wayne",
  email: "manager@example.com",
  password_hash: Bcrypt.hash_pwd_salt("password123"),
  role: "manager",
  status: "active"
})

{:ok, emp_dick} = Repo.insert(%User{
  username: "Dick Grayson",
  email: "employee1@example.com",
  password_hash: Bcrypt.hash_pwd_salt("password123"),
  role: "employee",
  status: "active",
  contract_start: ~D[2023-01-01]
})

{:ok, emp_barbara} = Repo.insert(%User{
  username: "Barbara Gordon",
  email: "employee2@example.com",
  password_hash: Bcrypt.hash_pwd_salt("password123"),
  role: "employee",
  status: "active",
  contract_start: ~D[2023-05-15]
})

# Insert Teams
{:ok, team_bat} = Repo.insert(%Team{
  name: "Bat Family",
  manager_id: manager_bruce.id
})

# Assign Users to Teams
Repo.insert(%TeamUser{team_id: team_bat.id, user_id: emp_dick.id})
Repo.insert(%TeamUser{team_id: team_bat.id, user_id: emp_barbara.id})

# Generate Past 7 Days Working Times and Clocks for Employees
now = DateTime.utc_now() |> DateTime.truncate(:second)

for user <- [emp_dick, emp_barbara] do
  for days_ago <- 7..1 do
    # Shift: 9:00 AM to 5:00 PM (8 hours)
    start_time = DateTime.add(now, -days_ago * 86400, :second) |> %{now | hour: 9, minute: 0, second: 0}
    end_time = DateTime.add(now, -days_ago * 86400, :second) |> %{now | hour: 17, minute: 0, second: 0}
    
    # Randomly skip some days to create "oublis" (forgotten clocks) for fatigue/manager checks
    is_missed = (user.id == emp_dick.id and days_ago == 2)

    unless is_missed do
      # Create Working Time
      Repo.insert(%WorkingTime{
        user_id: user.id,
        start: start_time,
        end: end_time
      })

      # Create Clocks (In and Out)
      Repo.insert(%Clock{
        user_id: user.id,
        time: start_time,
        status: true
      })
      Repo.insert(%Clock{
        user_id: user.id,
        time: end_time,
        status: false
      })
    else
      # Missed clock out: only clocked in
      Repo.insert(%Clock{
        user_id: user.id,
        time: start_time,
        status: true
      })
    end
  end
end

IO.puts("✅ Database successfully seeded with realistic Gotham data!")
