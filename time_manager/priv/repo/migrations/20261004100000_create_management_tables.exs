defmodule TimeManager.Repo.Migrations.CreateManagementTables do
  use Ecto.Migration

  def up do
    execute("""
    CREATE TABLE IF NOT EXISTS teams (
      id bigserial PRIMARY KEY,
      name varchar NOT NULL,
      manager_id bigint,
      inserted_at timestamptz NOT NULL,
      updated_at timestamptz NOT NULL
    )
    """)

    execute("ALTER TABLE teams ADD COLUMN IF NOT EXISTS manager_id bigint")

    execute("""
    DO $$ BEGIN
      IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'teams_manager_fk') THEN
        ALTER TABLE teams ADD CONSTRAINT teams_manager_fk FOREIGN KEY (manager_id) REFERENCES users(id) ON DELETE SET NULL;
      END IF;
    END $$;
    """)

    execute("CREATE UNIQUE INDEX IF NOT EXISTS teams_name_index ON teams (name)")
    execute("CREATE INDEX IF NOT EXISTS teams_manager_id_index ON teams (manager_id)")

    execute("""
    CREATE TABLE IF NOT EXISTS team_memberships (
      id bigserial PRIMARY KEY,
      team_id bigint NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
      user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      active boolean NOT NULL DEFAULT true,
      inserted_at timestamptz NOT NULL,
      updated_at timestamptz NOT NULL,
      CONSTRAINT team_memberships_team_user_index UNIQUE (team_id, user_id)
    )
    """)

    execute("ALTER TABLE team_memberships ADD COLUMN IF NOT EXISTS id bigserial")

    execute(
      "ALTER TABLE team_memberships ADD COLUMN IF NOT EXISTS active boolean NOT NULL DEFAULT true"
    )

    execute(
      "CREATE INDEX IF NOT EXISTS team_memberships_user_id_index ON team_memberships (user_id)"
    )

    execute("""
    CREATE TABLE IF NOT EXISTS leave_requests (
      id bigserial PRIMARY KEY,
      type varchar NOT NULL,
      start_date date NOT NULL,
      end_date date NOT NULL,
      reason text,
      status varchar NOT NULL DEFAULT 'pending',
      user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      reviewed_by_id bigint REFERENCES users(id) ON DELETE SET NULL,
      reviewed_at timestamptz,
      inserted_at timestamptz NOT NULL,
      updated_at timestamptz NOT NULL
    )
    """)

    execute(
      "CREATE INDEX IF NOT EXISTS leave_requests_user_status_index ON leave_requests (user_id, status)"
    )

    execute("CREATE INDEX IF NOT EXISTS leave_requests_status_index ON leave_requests (status)")

    execute("""
    CREATE TABLE IF NOT EXISTS payroll_rules (
      id bigserial PRIMARY KEY,
      name varchar NOT NULL,
      rule_type varchar NOT NULL,
      value numeric NOT NULL,
      active boolean NOT NULL DEFAULT true,
      created_by_id bigint REFERENCES users(id) ON DELETE SET NULL,
      inserted_at timestamptz NOT NULL,
      updated_at timestamptz NOT NULL
    )
    """)

    execute("CREATE UNIQUE INDEX IF NOT EXISTS payroll_rules_name_index ON payroll_rules (name)")

    execute("""
    CREATE TABLE IF NOT EXISTS work_policies (
      id bigserial PRIMARY KEY,
      name varchar NOT NULL,
      weekly_hours numeric NOT NULL,
      work_days integer NOT NULL DEFAULT 5,
      night_start time NOT NULL,
      night_end time NOT NULL,
      overtime_threshold numeric NOT NULL,
      active boolean NOT NULL DEFAULT true,
      inserted_at timestamptz NOT NULL,
      updated_at timestamptz NOT NULL
    )
    """)

    execute(
      "ALTER TABLE work_policies ADD COLUMN IF NOT EXISTS work_days integer NOT NULL DEFAULT 5"
    )

    execute("CREATE UNIQUE INDEX IF NOT EXISTS work_policies_name_index ON work_policies (name)")

    execute("""
    CREATE TABLE IF NOT EXISTS user_work_policies (
      id bigserial PRIMARY KEY,
      user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      policy_id bigint NOT NULL REFERENCES work_policies(id) ON DELETE RESTRICT,
      starts_on date NOT NULL,
      ends_on date,
      inserted_at timestamptz NOT NULL,
      updated_at timestamptz NOT NULL
    )
    """)

    execute(
      "CREATE INDEX IF NOT EXISTS user_work_policies_user_start_index ON user_work_policies (user_id, starts_on)"
    )
  end

  def down do
    execute("DROP TABLE IF EXISTS user_work_policies")
    execute("DROP TABLE IF EXISTS work_policies")
    execute("DROP TABLE IF EXISTS payroll_rules")
    execute("DROP TABLE IF EXISTS leave_requests")
    execute("DROP TABLE IF EXISTS team_memberships")
    execute("DROP TABLE IF EXISTS teams")
  end
end
