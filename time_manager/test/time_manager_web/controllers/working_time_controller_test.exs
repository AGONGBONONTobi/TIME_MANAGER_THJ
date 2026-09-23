defmodule TimeManagerWeb.WorkingTimeControllerTest do
  use TimeManagerWeb.ConnCase

  alias TimeManager.Accounts

  setup %{conn: conn} do
    {:ok, user} =
      Accounts.create_user(%{username: "api-working-user", email: "api-working@example.com"})

    {:ok, conn: put_req_header(conn, "accept", "application/json"), user: user}
  end

  test "workingtime CRUD uses the required routes", %{conn: conn, user: user} do
    created = post(conn, "/api/workingtime/#{user.id}")
    assert %{"id" => id, "user_id" => user_id} = json_response(created, 201)["data"]
    assert user_id == user.id
    assert json_response(created, 201)["data"]["end"] == nil

    listed = get(conn, "/api/workingtime/#{user.id}")
    assert [%{"id" => ^id}] = json_response(listed, 200)["data"]

    updated =
      put(conn, "/api/workingtime/#{id}", %{"end_at" => "2026-09-20T18:00:00Z"})

    assert %{"id" => ^id, "end" => "2026-09-20T18:00:00Z"} = json_response(updated, 200)["data"]

    assert response(delete(conn, "/api/workingtime/#{id}"), 204) == ""
    assert response(get(conn, "/api/workingtime/#{user.id}/#{id}"), 404) == ""
  end

  test "workingtime POST uses the clock arrival/departure workflow", %{conn: conn, user: user} do
    arrival = post(conn, "/api/workingtime/#{user.id}")
    assert response(arrival, 201)
    assert json_response(arrival, 201)["data"]["end"] == nil

    departure = post(conn, "/api/workingtime/#{user.id}")
    assert response(departure, 201)
    assert json_response(departure, 201)["data"]["end"] != nil
  end
end
