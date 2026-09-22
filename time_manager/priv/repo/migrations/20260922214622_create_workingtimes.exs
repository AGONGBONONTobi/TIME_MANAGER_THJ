defmodule TimeManager.Repo.Migrations.CreateWorkingtimes do
  use Ecto.Migration

  def change do
    create table(:workingtimes) do
      add :start_at, :utc_datetime, null: false
      add :end_at,   :utc_datetime
      add :user_id,  references(:users, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create index(:workingtimes, [:user_id])
    create index(:workingtimes, [:user_id, :end_at])
  end
end
