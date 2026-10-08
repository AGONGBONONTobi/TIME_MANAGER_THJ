defmodule TimeManager.Repo.Migrations.CreateClockCorrections do
  use Ecto.Migration

  def change do
    create table(:clock_corrections) do
      add :original_clock_id, references(:clocks, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :proposed_time, :utc_datetime, null: false
      add :proposed_status, :boolean, null: false
      add :reason, :text
      add :status, :string, default: "pending"
      add :reviewed_by_id, references(:users, on_delete: :nothing)
      add :reviewed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:clock_corrections, [:user_id])
    create index(:clock_corrections, [:original_clock_id])
    create index(:clock_corrections, [:reviewed_by_id])
  end
end
