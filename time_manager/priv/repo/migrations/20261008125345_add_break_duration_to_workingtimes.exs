defmodule TimeManager.Repo.Migrations.AddBreakDurationToWorkingtimes do
  use Ecto.Migration

  def change do
    alter table(:workingtimes) do
      add :break_duration, :integer, default: 0
    end
  end
end
