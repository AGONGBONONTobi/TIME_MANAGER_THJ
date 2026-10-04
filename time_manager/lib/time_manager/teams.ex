defmodule TimeManager.Teams do
  import Ecto.Query, warn: false
  alias TimeManager.Repo
  alias TimeManager.Teams.{Team, TeamMembership, TeamTask}

  def list_teams do
    Repo.all(from t in Team, preload: [memberships: :user])
  end

  def get_team(id), do: Repo.get(Team, id) |> preload_team()

  def create_team(attrs), do: %Team{} |> Team.changeset(attrs) |> Repo.insert()

  def update_team(%Team{} = team, attrs), do: team |> Team.changeset(attrs) |> Repo.update()

  def delete_team(%Team{} = team), do: Repo.delete(team)

  def add_member(team_id, user_id) do
    %TeamMembership{}
    |> TeamMembership.changeset(%{team_id: team_id, user_id: user_id, active: true})
    |> Repo.insert(on_conflict: [set: [active: true]], conflict_target: [:team_id, :user_id])
  end

  def remove_member(team_id, user_id) do
    case Repo.get_by(TeamMembership, team_id: team_id, user_id: user_id) do
      nil -> {:error, :not_found}
      membership -> Repo.delete(membership)
    end
  end

  def list_tasks(team_id), do: Repo.all(from task in TeamTask, where: task.team_id == ^team_id, order_by: [asc: task.status, asc: task.due_date, desc: task.inserted_at])

  def create_task(team_id, user_id, attrs) do
    attrs
    |> Map.merge(%{"team_id" => team_id, "created_by_id" => user_id})
    |> then(&%TeamTask{} |> TeamTask.changeset(&1) |> Repo.insert())
  end

  def update_task_status(task_id, status) when status in ["pending", "completed"] do
    case Repo.get(TeamTask, task_id) do
      nil -> {:error, :not_found}
      task -> task |> TeamTask.status_changeset(status) |> Repo.update()
    end
  end

  defp preload_team(nil), do: nil
  defp preload_team(team), do: Repo.preload(team, memberships: :user)
end