defmodule TimeManager.Repo.Migrations.AddAuthFieldsToUsers do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash varchar")

    execute("""
    ALTER TABLE users
    ADD COLUMN IF NOT EXISTS role varchar DEFAULT 'employee'
    """)

    execute("UPDATE users SET role = 'employee' WHERE role IS NULL")
  end

  def down do
    alter table(:users) do
      remove :password_hash
      remove :role
    end
  end
end
