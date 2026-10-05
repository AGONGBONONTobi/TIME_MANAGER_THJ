defmodule TimeManager.Repo.Migrations.CreateTeamTasks do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE teams ADD COLUMN IF NOT EXISTS description text")

    execute("""
    CREATE TABLE IF NOT EXISTS team_tasks (
      id bigserial PRIMARY KEY,
      team_id bigint NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
      created_by_id bigint NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
      title varchar NOT NULL,
      description text,
      status varchar NOT NULL DEFAULT 'pending',
      due_date date,
      completed_at timestamptz,
      inserted_at timestamptz NOT NULL,
      updated_at timestamptz NOT NULL
    )
    """)

    execute(
      "CREATE INDEX IF NOT EXISTS team_tasks_team_status_index ON team_tasks (team_id, status)"
    )

    execute("CREATE INDEX IF NOT EXISTS team_tasks_due_date_index ON team_tasks (due_date)")
  end

  def down do
    execute("DROP TABLE IF EXISTS team_tasks")
    execute("ALTER TABLE teams DROP COLUMN IF EXISTS description")
  end
end
