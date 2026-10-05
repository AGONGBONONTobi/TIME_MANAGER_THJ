defmodule TimeManager.Repo.Migrations.AddWorkDaysToWorkPolicies do
  use Ecto.Migration

  def up do
    execute(
      "ALTER TABLE work_policies ADD COLUMN IF NOT EXISTS work_days integer NOT NULL DEFAULT 5"
    )
  end

  def down do
    execute("ALTER TABLE work_policies DROP COLUMN IF EXISTS work_days")
  end
end
