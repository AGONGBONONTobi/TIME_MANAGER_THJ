defmodule TimeManagerWeb.ClockCorrectionController do
  use TimeManagerWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias TimeManager.Clocking

  action_fallback TimeManagerWeb.FallbackController

  def index(conn, _params) do
    user_id = conn.assigns.current_user.id
    corrections = Clocking.list_clock_corrections(user_id)
    render(conn, :index, clock_corrections: corrections)
  end

  def index_for_manager(conn, _params) do
    # Assuming manager can see all pending corrections for their team
    # For now, let's just list all or list based on team logic.
    # We will just list all pending for simplicity if they are admin/manager.
    corrections = Clocking.list_pending_clock_corrections()
    render(conn, :index, clock_corrections: corrections)
  end

  def create(conn, %{"clock_correction" => correction_params}) do
    user_id = conn.assigns.current_user.id
    params = Map.put(correction_params, "user_id", user_id)

    case Clocking.create_clock_correction(params) do
      {:ok, correction} ->
        conn
        |> put_status(:created)
        |> render(:show, clock_correction: correction)

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> put_view(json: TimeManagerWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)
    end
  end

  def approve(conn, %{"id" => id}) do
    manager_id = conn.assigns.current_user.id

    case Clocking.approve_clock_correction(id, manager_id) do
      {:ok, correction} ->
        conn |> put_status(:ok) |> render(:show, clock_correction: correction)

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Correction request not found"})

      {:error, _reason} ->
        conn |> put_status(:bad_request) |> json(%{error: "Failed to approve"})
    end
  end

  def reject(conn, %{"id" => id}) do
    manager_id = conn.assigns.current_user.id

    case Clocking.reject_clock_correction(id, manager_id) do
      {:ok, correction} ->
        conn |> put_status(:ok) |> render(:show, clock_correction: correction)

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Correction request not found"})

      {:error, _reason} ->
        conn |> put_status(:bad_request) |> json(%{error: "Failed to reject"})
    end
  end
end
