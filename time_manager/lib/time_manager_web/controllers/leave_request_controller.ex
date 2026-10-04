defmodule TimeManagerWeb.LeaveRequestController do
  use TimeManagerWeb, :controller

  alias TimeManager.LeaveRequests

  def index(conn, _params) do
    requests = if conn.assigns.current_user.role in ["manager", "admin"], do: LeaveRequests.list_all(), else: LeaveRequests.list_for_user(conn.assigns.current_user.id)
    json(conn, %{data: Enum.map(requests, &data/1)})
  end

  def create(conn, params) do
    case LeaveRequests.create_for_user(conn.assigns.current_user.id, Map.get(params, "leave_request", params)) do
      {:ok, request} -> conn |> put_status(:created) |> json(%{data: data(request)})
      {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "Invalid data", details: Ecto.Changeset.traverse_errors(changeset, fn {message, _} -> message end)})
    end
  end

  def approve(conn, %{"id" => id}), do: review(conn, id, "approved")
  def reject(conn, %{"id" => id}), do: review(conn, id, "rejected")

  defp review(conn, id, status) do
    with request when not is_nil(request) <- LeaveRequests.get(id),
         {:ok, reviewed} <- LeaveRequests.review(request, conn.assigns.current_user.id, status) do
      json(conn, %{data: data(reviewed)})
    else
      nil -> send_resp(conn, :not_found, "")
      {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "Invalid review", details: Ecto.Changeset.traverse_errors(changeset, fn {message, _} -> message end)})
    end
  end

  defp data(request), do: %{id: request.id, user_id: request.user_id, type: request.type, start_date: request.start_date, end_date: request.end_date, reason: request.reason, status: request.status, reviewed_by_id: request.reviewed_by_id, reviewed_at: request.reviewed_at}
end