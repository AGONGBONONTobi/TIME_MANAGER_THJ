defmodule TimeManagerWeb.WorkingTimeController do
  use TimeManagerWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias TimeManager.Clocking
  alias TimeManager.WorkingTimes

  action_fallback(TimeManagerWeb.FallbackController)

  operation(:index,
    summary: "List working times for a user",
    parameters: [
      userID: [in: :path, required: true, type: :string],
      start: [in: :query, type: :string],
      end: [in: :query, type: :string]
    ],
    responses: [ok: "Working times returned"]
  )

  operation(:show,
    summary: "Get a working time",
    parameters: [
      userID: [in: :path, required: true, type: :string],
      id: [in: :path, required: true, type: :string]
    ],
    responses: [ok: "Working time returned", not_found: "Working time not found"]
  )

  operation(:create,
    summary: "Create a working time",
    parameters: [userID: [in: :path, required: true, type: :string]],
    responses: [created: "Working time created", bad_request: "Invalid working time"]
  )

  operation(:update,
    summary: "Update a working time",
    parameters: [id: [in: :path, required: true, type: :string]],
    responses: [
      ok: "Working time updated",
      bad_request: "Invalid working time",
      not_found: "Working time not found"
    ]
  )

  operation(:delete,
    summary: "Delete a working time",
    parameters: [id: [in: :path, required: true, type: :string]],
    responses: [no_content: "Working time deleted", not_found: "Working time not found"]
  )

  # GET /api/workingtime/:userID?start=X&end=Y
  def index(conn, %{"userID" => user_id} = params) do
    working_times = WorkingTimes.list_for_user(user_id, params["start"], params["end"])
    render(conn, :index, working_times: working_times)
  end

  # GET /api/workingtime/:userID/:id
  def show(conn, %{"userID" => user_id, "id" => id}) do
    case WorkingTimes.get_for_user(user_id, id) do
      nil ->
        send_resp(conn, :not_found, "")

      working_time ->
        conn
        |> put_status(200)
        |> render(:show, working_time: working_time)
    end
  end

  # POST /api/workingtime/:userID
  def create(conn, %{"userID" => user_id} = params) do
    attrs = working_time_attrs(params)

    if attrs == %{} do
      case Clocking.create_clock(user_id) do
        {:ok, clock} ->
          working_time = WorkingTimes.get_by_clock_time(user_id, clock.time, clock.status)

          conn
          |> put_status(201)
          |> render(:show, working_time: working_time)

        {:error, :user_not_found} ->
          send_resp(conn, :not_found, "")

        {:error, reason} ->
          conn |> put_status(:unprocessable_entity) |> json(%{error: inspect(reason)})
      end
    else
      case WorkingTimes.create_for_user(user_id, attrs) do
        {:ok, wt} ->
          conn
          |> put_status(201)
          |> render(:show, working_time: wt)

        {:error, changeset} ->
          conn
          |> put_status(400)
          |> put_view(json: TimeManagerWeb.ChangesetJSON)
          |> render(:error, changeset: changeset)
      end
    end
  end

  # PUT /api/workingtime/:id
  def update(conn, %{"id" => id} = params) do
    case WorkingTimes.get_working_time(id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "WorkingTime not found"})

      working_time ->
        attrs =
          working_time_attrs(params)

        case WorkingTimes.update_working_time(working_time, attrs) do
          {:ok, wt} ->
            conn
            |> put_status(200)
            |> render(:show, working_time: wt)

          {:error, changeset} ->
            conn
            |> put_status(400)
            |> put_view(json: TimeManagerWeb.ChangesetJSON)
            |> render(:error, changeset: changeset)
        end
    end
  end

  def update_for_user(conn, %{"userID" => user_id, "id" => id} = params) do
    case WorkingTimes.get_for_user(user_id, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "WorkingTime not found"})

      working_time ->
        update_working_time_response(conn, working_time, working_time_attrs(params))
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

  def delete_for_user(conn, %{"userID" => user_id, "id" => id}) do
    case WorkingTimes.get_for_user(user_id, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "WorkingTime not found"})

      working_time ->
        WorkingTimes.delete_working_time(working_time)
        send_resp(conn, :no_content, "")
    end
  end

  defp update_working_time_response(conn, working_time, attrs) do
    case WorkingTimes.update_working_time(working_time, attrs) do
      {:ok, wt} ->
        conn |> put_status(:ok) |> render(:show, working_time: wt)

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> put_view(json: TimeManagerWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)
    end
  end

  defp working_time_attrs(params) do
    params
    |> Map.get("workingtime", params)
    |> Map.take(["start", "end", "start_at", "end_at"])
    |> Map.new(fn
      {"start_at", value} -> {"start", value}
      {"end_at", value} -> {"end", value}
      pair -> pair
    end)
  end
end
