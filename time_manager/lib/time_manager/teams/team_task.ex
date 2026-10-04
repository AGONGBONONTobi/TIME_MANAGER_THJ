defmodule TimeManager.Teams.TeamTask do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending completed)

  schema "team_tasks" do
    field :title, :string
    field :description, :string
    field :status, :string, default: "pending"
    field :due_date, :date
    field :completed_at, :utc_datetime
    belongs_to :team, TimeManager.Teams.Team
    belongs_to :created_by, TimeManager.Accounts.User
    timestamps(type: :utc_datetime)
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:team_id, :created_by_id, :title, :description, :due_date])
    |> validate_required([:team_id, :created_by_id, :title])
    |> validate_length(:title, max: 160)
    |> foreign_key_constraint(:team_id)
    |> foreign_key_constraint(:created_by_id)
  end

  def status_changeset(task, status) when status in @statuses do
    task
    |> change(status: status, completed_at: if(status == "completed", do: DateTime.utc_now() |> DateTime.truncate(:second), else: nil))
  end
end
