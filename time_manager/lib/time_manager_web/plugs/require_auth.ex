defmodule TimeManagerWeb.Plugs.RequireAuth do
  @moduledoc false

  import Plug.Conn

  alias TimeManager.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> Plug.Conn.put_status(:unauthorized)
        |> Phoenix.Controller.json(%{error: "Authentication required"})
        |> halt()

      user_id ->
        case Accounts.get_user(user_id) do
          nil ->
            conn
            |> Plug.Conn.put_status(:unauthorized)
            |> Phoenix.Controller.json(%{error: "Authentication required"})
            |> halt()

          user ->
            conn
            |> assign(:current_user, user)
            |> assign(:current_user_id, user.id)
        end
    end
  end
end
