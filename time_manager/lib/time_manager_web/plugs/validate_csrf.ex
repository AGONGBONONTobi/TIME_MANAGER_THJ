defmodule TimeManagerWeb.Plugs.ValidateCsrf do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{method: method} = conn, _opts) do
    if method in ["POST", "PUT", "PATCH", "DELETE"] do
      conn = fetch_cookies(conn)
      auth_token = conn.cookies["auth_token"] || bearer_token(conn)

      expected =
        with token when not is_nil(token) <- auth_token,
             {:ok, claims} <- TimeManager.Token.verify_and_validate(token) do
          claims["csrf_token"]
        else
          _ -> nil
        end

      received = get_req_header(conn, "x-xsrf-token") |> List.first()

      case {expected, received} do
        {nil, _} ->
          conn
          |> Plug.Conn.put_status(:forbidden)
          |> Phoenix.Controller.json(%{error: "Invalid CSRF token"})
          |> halt()

        {_, nil} ->
          conn
          |> Plug.Conn.put_status(:forbidden)
          |> Phoenix.Controller.json(%{error: "Invalid CSRF token"})
          |> halt()

        {expected, received} when expected == received ->
          conn

        _ ->
          conn
          |> Plug.Conn.put_status(:forbidden)
          |> Phoenix.Controller.json(%{error: "Invalid CSRF token"})
          |> halt()
      end
    else
      conn
    end
  end

  defp bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token | _] -> token
      _ -> nil
    end
  end
end
