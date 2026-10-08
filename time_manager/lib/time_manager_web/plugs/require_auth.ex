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
      conn
      |> assign(:current_user, user)
      |> assign(:current_user_id, user.id)
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
end
