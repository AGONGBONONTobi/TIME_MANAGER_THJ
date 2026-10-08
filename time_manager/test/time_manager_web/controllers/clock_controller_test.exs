defmodule TimeManagerWeb.ClockControllerTest do
  use TimeManagerWeb.ConnCase

  alias TimeManager.Accounts

  setup %{conn: conn} do
    {:ok, user} =
      Accounts.create_user(%{username: "api-clock-user", email: "api-clock@example.com"})

    {:ok, conn: put_req_header(conn, "accept", "application/json"), user: user}
  end

  test "POST clocks creates arrival and departure", %{conn: conn, user: user} do
    conn = auth_conn(conn, user)

    arrival = post(conn, "/api/clocks/#{user.id}")
    assert %{"status" => true} = json_response(arrival, 201)["data"]

    departure = post(conn, "/api/clocks/#{user.id}")
    assert %{"status" => false} = json_response(departure, 201)["data"]

    clocks = get(conn, "/api/clocks/#{user.id}")
    assert length(json_response(clocks, 200)["data"]) == 2
  end

  test "unknown users are rejected", %{conn: conn, user: user} do
    conn = auth_conn(conn, user)
    assert response(post(conn, "/api/clocks/999999"), 404) == ""
  end

  # defp auth_conn(conn, user) do
  #   conn
  #   |> Plug.Test.init_test_session(%{user_id: user.id, csrf_token: "test-token"})
  #   |> put_req_header("x-xsrf-token", "test-token")
  # end
end
