defmodule TimeManagerWeb.WorkingTimeController do
  use TimeManagerWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias TimeManager.WorkingTimes

  action_fallback(TimeManagerWeb.FallbackController)

  operation :index,
    summary: "List working times for a user",
    parameters: [
      userID: [in: :path, required: true, type: :string],
      start: [in: :query, type: :string],
      end: [in: :query, type: :string]
    ],
    responses: [ok: "Working times returned"]

  operation :show,
    summary: "Get a working time",
    parameters: [
      userID: [in: :path, required: true, type: :string],
      id: [in: :path, required: true, type: :string]
    ],
    responses: [ok: "Working time returned", not_found: "Working time not found"]

  operation :create,
    summary: "Create a working time",
    parameters: [userID: [in: :path, required: true, type: :string]],
    responses: [created: "Working time created", bad_request: "Invalid working time"]

  operation :update,
    summary: "Update a working time",
    parameters: [id: [in: :path, required: true, type: :string]],
    responses: [ok: "Working time updated", bad_request: "Invalid working time", not_found: "Working time not found"]

  operation :delete,
    summary: "Delete a working time",
    parameters: [id: [in: :path, required: true, type: :string]],
    responses: [no_content: "Working time deleted", not_found: "Working time not found"]

  # GET /api/workingtime/:userID?start=X&end=Y
  def index(conn, %{"userID" => user_id} = params) do
    working_times = WorkingTimes.list_for_user(user_id, params["start"], params["end"])
    render(conn, :index, working_times: working_times)
  end

  # GET /api/workingtime/:userID/:id
  def show(conn, %{"userID" => user_id, "id" => id}) do
    case WorkingTimes.get_for_user(user_id, id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "WorkingTime not found"})

      working_time ->
        conn
        |> put_status(200)
        |> render(:show, working_time: working_time)
    end
  end

  # POST /api/workingtime/:userID
  def create(conn, %{"userID" => user_id} = params) do
    attrs =
      params
      |> Map.get("workingtime", params)
      |> Map.take(["start", "end"])
      |> Map.put("user_id", user_id)

    case WorkingTimes.create_working_time(attrs) do
      {:ok, wt} ->
        conn
        |> put_status(201)
        |> render(:show, working_time: wt)

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{error: "Bad request", details: changeset})
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
          params
          |> Map.get("workingtime", params)
          |> Map.take(["start", "end"])

        case WorkingTimes.update_working_time(working_time, attrs) do
          {:ok, wt} ->
            conn
            |> put_status(200)
            |> render(:show, working_time: wt)

          {:error, changeset} ->
            conn
            |> put_status(400)
            |> json(%{error: "Bad request", details: changeset})
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
