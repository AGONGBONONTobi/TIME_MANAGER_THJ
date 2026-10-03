defmodule TimeManager.Repo.Migrations.AddAuthFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :password_hash, :string
      add :role, :string, default: "employee"
    end
  end
end
