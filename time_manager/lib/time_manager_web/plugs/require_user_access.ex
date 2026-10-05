defmodule TimeManagerWeb.Plugs.RequireUserAccess do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    requested_user_id = conn.params["userID"] || conn.params["user_id"]
    current_user = conn.assigns.current_user

    allowed =
      is_nil(requested_user_id) or
        to_string(current_user.id) == to_string(requested_user_id) or
        current_user.role in ["manager", "admin"]

    if allowed do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> Phoenix.Controller.json(%{error: "You cannot access another user's data"})
      |> halt()
    end
  end
end