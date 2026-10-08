defmodule TimeManager.Repo.Migrations.AddLifecycleFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :contract_start, :date
      add :contract_end, :date
      add :status, :string, default: "active"
    end
  end
end
