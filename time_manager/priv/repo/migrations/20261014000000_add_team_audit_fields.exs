defmodule TimeManager.Repo.Migrations.AddTeamAuditFields do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :created_by_id, references(:users, on_delete: :nilify_all)
    end

    create index(:teams, [:created_by_id])
  end
end
