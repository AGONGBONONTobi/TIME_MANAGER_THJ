defmodule TimeManagerWeb.WorkingTimeControllerTest do
  use TimeManagerWeb.ConnCase

  alias TimeManager.Accounts

  setup %{conn: conn} do
    {:ok, user} =
      Accounts.create_user(%{username: "api-working-user", email: "api-working@example.com"})

    {:ok, conn: put_req_header(conn, "accept", "application/json"), user: user}
  end

  test "workingtime CRUD uses the required routes", %{conn: conn, user: user} do
    attrs = %{
      "working_time" => %{"start" => "2026-09-20T13:09:00Z", "end" => "2026-09-20T17:09:00Z"}
    }

    created = post(conn, "/api/workingtime/#{user.id}", attrs)
    assert %{"id" => id, "user_id" => user_id} = json_response(created, 201)["data"]
    assert user_id == user.id

    listed = get(conn, "/api/workingtime/#{user.id}")
    assert [%{"id" => ^id}] = json_response(listed, 200)["data"]

    updated =
      put(conn, "/api/workingtime/#{id}", %{"working_time" => %{"end" => "2026-09-20T18:00:00Z"}})

    assert %{"id" => ^id, "end" => "2026-09-20T18:00:00Z"} = json_response(updated, 200)["data"]

    assert response(delete(conn, "/api/workingtime/#{id}"), 204) == ""
    assert response(get(conn, "/api/workingtime/#{user.id}/#{id}"), 404) == ""
  end

  test "workingtime rejects a second open session", %{conn: conn, user: user} do
    assert response(post(conn, "/api/workingtime/#{user.id}"), 201)

    response = post(conn, "/api/workingtime/#{user.id}")
    assert json_response(response, 409)["error"] == "already clocked in"
  end
end
