defmodule TimeManagerWeb.Plugs.RequireRole do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    roles = Keyword.get(opts, :roles, [])
    user_role = to_string(conn.assigns.current_user.role)  # ← CONVERSION en string

    if user_role in roles do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> Phoenix.Controller.json(%{error: "Insufficient permissions"})
      |> halt()
    end
  end
end
