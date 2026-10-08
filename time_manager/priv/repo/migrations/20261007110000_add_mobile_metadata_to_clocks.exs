defmodule TimeManager.Repo.Migrations.AddMobileMetadataToClocks do
  use Ecto.Migration

  def change do
    alter table(:clocks) do
      add :client_event_id, :string
      add :source, :string, null: false, default: "web"
      add :received_at, :utc_datetime
    end

    create unique_index(:clocks, [:client_event_id],
             where: "client_event_id IS NOT NULL",
             name: :clocks_client_event_id_unique
           )
  end
end
