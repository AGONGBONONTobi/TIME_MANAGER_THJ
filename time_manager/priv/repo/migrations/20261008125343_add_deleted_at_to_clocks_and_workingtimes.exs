defmodule TimeManager.Repo.Migrations.AddDeletedAtToClocksAndWorkingtimes do
  use Ecto.Migration

  def change do
    alter table(:clocks) do
      add :deleted_at, :utc_datetime
    end

    alter table(:workingtimes) do
      add :deleted_at, :utc_datetime
    end
  end
end
