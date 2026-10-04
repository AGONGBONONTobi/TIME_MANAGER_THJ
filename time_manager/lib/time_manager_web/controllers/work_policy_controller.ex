defmodule TimeManagerWeb.WorkPolicyController do
  use TimeManagerWeb, :controller

  alias TimeManager.WorkPolicies

  def index(conn, _params), do: json(conn, %{data: Enum.map(WorkPolicies.list_all(), &data/1)})

  def create(conn, params) do
    case WorkPolicies.create(Map.get(params, "work_policy", params)) do
      {:ok, policy} -> conn |> put_status(:created) |> json(%{data: data(policy)})
      {:error, changeset} -> validation_error(conn, changeset)
    end
  end

  def update(conn, %{"id" => id} = params) do
    with policy when not is_nil(policy) <- WorkPolicies.get(id),
         {:ok, updated} <- WorkPolicies.update(policy, Map.get(params, "work_policy", params)) do
      json(conn, %{data: data(updated)})
    else
      nil -> send_resp(conn, :not_found, "")
      {:error, changeset} -> validation_error(conn, changeset)
    end
  end

  def assign(conn, %{"user_id" => user_id, "policy_id" => policy_id} = params) do
    case WorkPolicies.assign(user_id, policy_id, params["starts_on"] || Date.utc_today()) do
      {:ok, assignment} -> conn |> put_status(:created) |> json(%{data: %{id: assignment.id, user_id: assignment.user_id, policy_id: assignment.policy_id, starts_on: assignment.starts_on}})
      {:error, changeset} -> validation_error(conn, changeset)
    end
  end

  def show_for_user(conn, %{"userID" => user_id}) do
    case WorkPolicies.get_for_user(user_id) do
      nil -> send_resp(conn, :not_found, "")
      assignment -> json(conn, %{data: data(assignment.policy)})
    end
  end

  defp data(policy), do: %{id: policy.id, name: policy.name, weekly_hours: policy.weekly_hours, work_days: policy.work_days, night_start: policy.night_start, night_end: policy.night_end, overtime_threshold: policy.overtime_threshold, active: policy.active}
  defp validation_error(conn, changeset), do: conn |> put_status(:unprocessable_entity) |> json(%{error: "Invalid data", details: Ecto.Changeset.traverse_errors(changeset, fn {message, _} -> message end)})
end