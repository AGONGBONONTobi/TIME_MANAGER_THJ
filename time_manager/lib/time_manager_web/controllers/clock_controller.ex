defmodule TimeManagerWeb.ClockController do
  use TimeManagerWeb, :controller

  alias TimeManager.Clocking

  action_fallback TimeManagerWeb.FallbackController

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
  def create(conn, %{"userID" => user_id}) do
    with {:ok, clock} <- Clocking.create_clock(user_id) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/clocks/#{clock.user_id}")
      |> render(:show, clock: clock)
    end
  end
end
