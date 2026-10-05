defmodule TimeManagerWeb.TeamController do
  use TimeManagerWeb, :controller

  alias TimeManager.Teams

  def index(conn, _params) do
    teams =
      Teams.list_teams()
      |> Enum.filter(fn team -> conn.assigns.current_user.role == "admin" or team.manager_id == conn.assigns.current_user.id end)

    json(conn, %{data: Enum.map(teams, &team_data/1)})
  end

  def show(conn, %{"id" => id}) do
    case Teams.get_team(id) do
      nil -> send_resp(conn, :not_found, "")
      team when conn.assigns.current_user.role == "admin" or team.manager_id == conn.assigns.current_user.id -> json(conn, %{data: team_data(team)})
      _team -> forbidden(conn)
    end
  end

  def create(conn, params) do
    case Teams.create_team(Map.get(params, "team", params)) do
      {:ok, team} -> conn |> put_status(:created) |> json(%{data: team_data(team)})
      {:error, changeset} -> validation_error(conn, changeset)
    end
  end

  def update(conn, %{"id" => id} = params) do
    with team when not is_nil(team) <- Teams.get_team(id),
         {:ok, updated} <- Teams.update_team(team, Map.get(params, "team", params)) do
      json(conn, %{data: team_data(updated)})
    else
      nil -> send_resp(conn, :not_found, "")
      {:error, changeset} -> validation_error(conn, changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    case Teams.get_team(id) do
      nil -> send_resp(conn, :not_found, "")
      team -> Teams.delete_team(team) && send_resp(conn, :no_content, "")
    end
  end

  def add_member(conn, %{"id" => team_id, "user_id" => user_id}) do
    with team when not is_nil(team) <- Teams.get_team(team_id),
         true <- can_manage_members?(conn, team),
         {:ok, membership} <- Teams.add_member(team_id, user_id) do
      conn |> put_status(:created) |> json(%{data: %{id: membership.id, team_id: membership.team_id, user_id: membership.user_id}})
    else
      nil -> send_resp(conn, :not_found, "")
      false -> forbidden(conn)
      {:error, changeset} -> validation_error(conn, changeset)
    end
  end

  def remove_member(conn, %{"id" => team_id, "user_id" => user_id}) do
    with team when not is_nil(team) <- Teams.get_team(team_id),
         true <- can_manage_members?(conn, team),
         {:ok, _} <- Teams.remove_member(team_id, user_id) do
      send_resp(conn, :no_content, "")
    else
      nil -> send_resp(conn, :not_found, "")
      false -> forbidden(conn)
      {:error, :not_found} -> send_resp(conn, :not_found, "")
    end
  end

  defp can_manage_members?(conn, team) do
    conn.assigns.current_user.role == "admin" or team.manager_id == conn.assigns.current_user.id
  end

  defp forbidden(conn), do: conn |> put_status(:forbidden) |> json(%{error: "You can only manage members of your own team"})

  defp team_data(team) do
    %{id: team.id, name: team.name, description: team.description, manager_id: team.manager_id, members: Enum.map(team.memberships || [], fn membership -> %{id: membership.user.id, username: membership.user.username, email: membership.user.email, active: membership.active} end)}
  end

  defp validation_error(conn, changeset), do: conn |> put_status(:unprocessable_entity) |> json(%{error: "Invalid data", details: translate_errors(changeset)})
  defp translate_errors(changeset), do: Ecto.Changeset.traverse_errors(changeset, fn {message, _} -> message end)
end