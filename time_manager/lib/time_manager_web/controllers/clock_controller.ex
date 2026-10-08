defmodule TimeManagerWeb.ClockController do
  use TimeManagerWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias TimeManager.Clocking

  action_fallback TimeManagerWeb.FallbackController

  operation(:index,
    summary: "List clocks for a user",
    parameters: [userID: [in: :path, required: true, type: :string]],
    responses: [ok: "Clocks returned"]
  )

  operation(:create,
    summary: "Clock in or out for a user",
    parameters: [userID: [in: :path, required: true, type: :string]],
    responses: [
      created: "Clock created",
      not_found: "User not found",
      conflict: "User is already clocked in",
      unprocessable_entity: "User is not clocked in"
    ]
  )

  @doc """
  GET /api/clocks/:userID
  Retourne tous les clocks de l'utilisateur.
  """
  def index(conn, %{"userID" => user_id}) do
    clocks = Clocking.list_clocks(user_id)
    render(conn, :index, clocks: clocks)
  end

  @doc """
  POST /api/clocks/:userID
  Crée un nouveau clock (arrivée ou départ) pour l'utilisateur.
  """
  def create(conn, %{"userID" => user_id} = params) do
    case Clocking.create_clock(user_id, params) do
      {:ok, clock} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", ~p"/api/clocks/#{clock.user_id}")
        |> render(:show, clock: clock)

      {:error, :user_not_found} ->
        send_resp(conn, :not_found, "")

      {:error, :already_clocked_in} ->
        conn |> put_status(:conflict) |> json(%{error: "already clocked in"})

      {:error, :not_clocked_in} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "not clocked in"})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid clock event", details: translate_errors(changeset)})
    end
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
  end
end
