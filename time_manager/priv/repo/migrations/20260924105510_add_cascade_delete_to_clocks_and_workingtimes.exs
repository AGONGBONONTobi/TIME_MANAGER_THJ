defmodule TimeManager.Repo.Migrations.AddCascadeDeleteToClocksAndWorkingtimes do
  use Ecto.Migration

  def up do
    # Supprimer les anciennes contraintes
    drop constraint(:clocks, "clocks_user_id_fkey")
    drop constraint(:workingtimes, "workingtimes_user_id_fkey")

    # Recréer avec ON DELETE CASCADE
    alter table(:clocks) do
      modify :user_id, references(:users, on_delete: :delete_all), null: false
    end

    alter table(:workingtimes) do
      modify :user_id, references(:users, on_delete: :delete_all), null: false
    end
  end

  def down do
    drop constraint(:clocks, "clocks_user_id_fkey")
    drop constraint(:workingtimes, "workingtimes_user_id_fkey")

    alter table(:clocks) do
      modify :user_id, references(:users, on_delete: :nothing), null: false
    end

    alter table(:workingtimes) do
      modify :user_id, references(:users, on_delete: :nothing), null: false
    end
  end
end