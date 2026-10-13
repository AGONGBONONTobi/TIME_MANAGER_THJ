defmodule TimeManagerWeb.Plugs.RequireAuth do
  @moduledoc false

  import Plug.Conn

  alias TimeManager.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    conn = fetch_cookies(conn)

    with token when not is_nil(token) <- conn.cookies["auth_token"] || bearer_token(conn),
         {:ok, claims} <- TimeManager.Token.verify_and_validate(token),
         %{"user_id" => user_id} <- claims,
         user when not is_nil(user) <- Accounts.get_user(user_id) do
      conn =
        conn
        |> assign(:current_user, user)
        |> assign(:current_user_id, user.id)

      if user.must_change_password and not allowed_during_password_change?(conn) do
        conn
        |> put_status(:forbidden)
        |> Phoenix.Controller.json(%{
          error: "Password change required",
          code: "password_change_required"
        })
        |> halt()
      else
        conn
      end
    else
      _ -> unauthorized(conn)
    end
  end

  defp unauthorized(conn) do
    conn
    |> Plug.Conn.put_status(:unauthorized)
    |> Phoenix.Controller.json(%{error: "Authentication required"})
    |> halt()
  end

  defp bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token | _] -> token
      _ -> nil
    end
  end

  defp allowed_during_password_change?(%{method: "GET", path_info: ["api", "auth", "me"]}),
    do: true

  defp allowed_during_password_change?(%{method: "PUT", path_info: ["api", "auth", "password"]}),
    do: true

  defp allowed_during_password_change?(%{method: "POST", path_info: ["api", "auth", "sign_out"]}),
    do: true

  defp allowed_during_password_change?(_conn), do: false
end
