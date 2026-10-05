defmodule TimeManager.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def up do
    execute("""
    CREATE TABLE IF NOT EXISTS notifications (
      id bigserial PRIMARY KEY,
      user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      type varchar NOT NULL,
      message text NOT NULL,
      read_at timestamptz,
      inserted_at timestamptz NOT NULL,
      updated_at timestamptz NOT NULL
    )
    """)

    execute(
      "CREATE INDEX IF NOT EXISTS notifications_user_read_index ON notifications (user_id, read_at)"
    )
  end

  def down do
    execute("DROP TABLE IF EXISTS notifications")
  end
end
