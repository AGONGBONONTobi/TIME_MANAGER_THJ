defmodule TimeManagerWeb.WorkingTimeController do
  use TimeManagerWeb, :controller

  alias TimeManager.WorkingTimes
  # alias TimeManager.WorkingTimes.WorkingTime

  action_fallback(TimeManagerWeb.FallbackController)

  # GET /workingtime/:user_id?start=&end=
  def index(conn, %{"user_id" => user_id} = params) do
    working_times = WorkingTimes.list_for_user(user_id, params["start"], params["end"])
    render(conn, :index, working_times: working_times)
  end

  # GET /workingtime/:user_id/:id
  def show(conn, %{"user_id" => user_id, "id" => id}) do
    working_time = WorkingTimes.get_for_user!(user_id, id)
    render(conn, :show, working_time: working_time)
  end

  # POST /workingtime/:user_id  → clock in
  def create(conn, %{"user_id" => user_id}) do
    case WorkingTimes.clock_in(user_id) do
      {:ok, wt} ->
        conn
        |> put_status(:created)
        |> render(:show, working_time: wt)

      {:error, :already_clocked_in} ->
        conn
        |> put_status(:conflict)
        |> json(%{error: "already clocked in"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)
    end
  end

  # PUT /workingtime/:id  → close/edit the session
  def update(conn, %{"id" => id} = params) do
    working_time = WorkingTimes.get_working_time!(id)
    attrs = Map.take(params, ["start_at", "end_at"])

    case WorkingTimes.update_working_time(working_time, attrs) do
      {:ok, wt} ->
        render(conn, :show, working_time: wt)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)
    end
  end

  # DELETE /workingtime/:id
  def delete(conn, %{"id" => id}) do
    working_time = WorkingTimes.get_working_time!(id)
    {:ok, _} = WorkingTimes.delete_working_time(working_time)
    send_resp(conn, :no_content, "")
  end
end
