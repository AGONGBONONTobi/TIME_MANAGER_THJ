defmodule TimeManagerWeb.Plugs.ValidateCsrf do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{method: method} = conn, _opts) do
    if method in ["POST", "PUT", "PATCH", "DELETE"] do
      expected = get_session(conn, :csrf_token)
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
end
