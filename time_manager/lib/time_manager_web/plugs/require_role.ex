defmodule TimeManagerWeb.Plugs.RequireRole do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    roles = Keyword.get(opts, :roles, [])

    if conn.assigns.current_user.role in roles do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> Phoenix.Controller.json(%{error: "Insufficient permissions"})
      |> halt()
    end
  end
end