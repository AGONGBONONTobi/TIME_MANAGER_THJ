defmodule TimeManagerWeb.WorkingTimeController do
  use TimeManagerWeb, :controller

  alias TimeManager.WorkingTimes

  action_fallback(TimeManagerWeb.FallbackController)

  # GET /api/workingtime/:userID?start=X&end=Y
  def index(conn, %{"userID" => user_id} = params) do
    working_times = WorkingTimes.list_for_user(user_id, params["start"], params["end"])
    render(conn, :index, working_times: working_times)
  end

  # GET /api/workingtime/:userID/:id
  def show(conn, %{"userID" => user_id, "id" => id}) do
    case WorkingTimes.get_for_user(user_id, id) do
      nil -> send_resp(conn, :not_found, "")
      working_time -> render(conn, :show, working_time: working_time)
    end
  end

  # POST /api/workingtime/:userID
  def create(conn, %{"userID" => user_id}) do
    case WorkingTimes.start_session(user_id) do
      {:ok, wt} ->
        conn
        |> put_status(201)
        |> render(:show, working_time: wt)

      {:error, :user_not_found} ->
        send_resp(conn, :not_found, "")

      {:error, :already_clocked_in} ->
        conn |> put_status(:conflict) |> json(%{error: "already clocked in"})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> render(:error, changeset: changeset)
    end
  end

  # PUT /api/workingtime/:id  → modifier
  def update(conn, %{"id" => id} = params) do
    case WorkingTimes.get_working_time(id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "WorkingTime not found"})

      working_time ->
        attrs = params |> Map.get("working_time", params) |> Map.take(["start", "end", "end_at"])

        attrs =
          if Map.has_key?(attrs, "end_at"),
            do: Map.put(attrs, "end", attrs["end_at"]),
            else: attrs

        attrs = Map.delete(attrs, "end_at")

        case WorkingTimes.update_working_time(working_time, attrs) do
          {:ok, wt} ->
            conn
            |> put_status(200)
            |> render(:show, working_time: wt)

          {:error, changeset} ->
            conn |> put_status(:unprocessable_entity) |> render(:error, changeset: changeset)
        end
    end
  end

  # DELETE /api/workingtime/:id
  def delete(conn, %{"id" => id}) do
    case WorkingTimes.get_working_time(id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "WorkingTime not found"})

      working_time ->
        WorkingTimes.delete_working_time(working_time)
        send_resp(conn, :no_content, "")
    end
  end
end
