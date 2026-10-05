defmodule TimeManager.LeaveRequests do
  import Ecto.Query, warn: false
  alias TimeManager.Repo
  alias TimeManager.LeaveRequests.LeaveRequest

  def list_for_user(user_id), do: Repo.all(from r in LeaveRequest, where: r.user_id == ^user_id, order_by: [desc: r.start_date])
  def list_all, do: Repo.all(from r in LeaveRequest, order_by: [desc: r.inserted_at])
  def get(id), do: Repo.get(LeaveRequest, id)

  def create_for_user(user_id, attrs) do
    attrs |> Map.put("user_id", user_id) |> then(&%LeaveRequest{} |> LeaveRequest.changeset(&1) |> Repo.insert())
  end

  def review(%LeaveRequest{} = request, reviewer_id, status) do
    request
    |> LeaveRequest.review_changeset(%{status: status, reviewed_by_id: reviewer_id, reviewed_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end
end