defmodule TimeManagerWeb.TeamTaskController do
  use TimeManagerWeb, :controller

  alias TimeManager.Teams

  def index(conn, %{"team_id" => team_id}) do
    with team when not is_nil(team) <- Teams.get_team(team_id),
         true <- can_manage?(conn, team) do
      json(conn, %{data: Enum.map(Teams.list_tasks(team_id), &task_data/1)})
    else
      nil -> send_resp(conn, :not_found, "")
      false -> forbidden(conn)
    end
  end

  def create(conn, %{"team_id" => team_id} = params) do
    with team when not is_nil(team) <- Teams.get_team(team_id),
         true <- can_manage?(conn, team),
         {:ok, task} <- Teams.create_task(team_id, conn.assigns.current_user.id, Map.get(params, "task", params)) do
      conn |> put_status(:created) |> json(%{data: task_data(task)})
    else
      nil -> send_resp(conn, :not_found, "")
      false -> forbidden(conn)
      {:error, changeset} -> validation_error(conn, changeset)
    end
  end

  def update_status(conn, %{"id" => task_id, "status" => status}) do
    with {:ok, task} <- fetch_authorized_task(conn, task_id),
         {:ok, updated} <- Teams.update_task_status(task.id, status) do
      json(conn, %{data: task_data(updated)})
    else
      {:error, :not_found} -> send_resp(conn, :not_found, "")
      {:error, :forbidden} -> forbidden(conn)
      {:error, changeset} -> validation_error(conn, changeset)
    end
  end

  defp fetch_authorized_task(conn, task_id) do
    task = TimeManager.Repo.get(TimeManager.Teams.TeamTask, task_id)

    case task && Teams.get_team(task.team_id) do
      nil -> {:error, :not_found}
      team -> if can_manage?(conn, team), do: {:ok, task}, else: {:error, :forbidden}
    end
  end

  defp can_manage?(conn, team), do: conn.assigns.current_user.role == "admin" or team.manager_id == conn.assigns.current_user.id
  defp forbidden(conn), do: conn |> put_status(:forbidden) |> json(%{error: "You can only manage tasks of your own team"})
  defp validation_error(conn, changeset), do: conn |> put_status(:unprocessable_entity) |> json(%{error: "Invalid task", details: Ecto.Changeset.traverse_errors(changeset, fn {message, _} -> message end)})
  defp task_data(task), do: %{id: task.id, team_id: task.team_id, created_by_id: task.created_by_id, title: task.title, description: task.description, status: task.status, due_date: task.due_date, completed_at: task.completed_at}
end
