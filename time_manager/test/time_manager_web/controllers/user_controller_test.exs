defmodule TimeManagerWeb.UserControllerTest do
  use TimeManagerWeb.ConnCase

  import TimeManager.AccountsFixtures
  alias TimeManager.Accounts.User

  @create_attrs %{
    username: "some username",
    email: "someemail-authenticated@gmail.com"
  }
  @update_attrs %{
    username: "some updated username",
    email: "someupdatedemail@gmail.com"
  }
  @invalid_attrs %{username: nil, email: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "requires authentication", %{conn: conn} do
      conn = get(conn, ~p"/api/users")
      assert json_response(conn, 401)["error"] == "Authentication required"
    end

    test "lists all users for authenticated users", %{conn: conn} do
      user = user_fixture()
      conn = auth_conn(conn, user)

      conn = get(conn, ~p"/api/users")
      users = json_response(conn, 200)["data"]

      assert Enum.any?(users, fn item ->
               item["id"] == user.id and item["email"] == user.email and item["username"] == user.username
             end)
    end
  end

  describe "show user" do
    setup do
      {:ok, %User{} = user} =
        TimeManager.Accounts.create_user(%{username: "Tobi", email: "test@example.com"})

      %{user: user}
    end

    test "renders user when id data is valid", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = get(conn, ~p"/api/users/#{user.id}")
      assert %{"id" => _id} = json_response(conn, 200)["data"]
    end

    test "render errors when user not found", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = get(conn, ~p"/api/users/258")
      assert json_response(conn, 404)["error"] == "User not found"
    end
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      user = user_fixture()
      conn = auth_conn(conn, user)
      conn = post(conn, ~p"/api/users", user: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/users/#{id}")

      assert %{
               "id" => ^id,
               "email" => "someemail-authenticated@gmail.com",
               "username" => "some username"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      user = user_fixture()
      conn = auth_conn(conn, user)
      conn = post(conn, ~p"/api/users", user: @invalid_attrs)
      assert json_response(conn, 400)["error"] != %{}
    end
  end

  describe "update user" do
    setup [:create_user]

    test "renders user when data is valid", %{conn: conn, user: %User{id: id} = user} do
      conn = auth_conn(conn, user)
      conn = put(conn, ~p"/api/users/#{user}", user: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/users/#{id}")

      assert %{
               "id" => ^id,
               "email" => "someupdatedemail@gmail.com",
               "username" => "some updated username"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = put(conn, ~p"/api/users/#{user}", user: @invalid_attrs)
      assert json_response(conn, 400)["error"] != %{}
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = auth_conn(conn, user)
      conn = delete(conn, ~p"/api/users/#{user}")
      assert response(conn, 204)

      assert TimeManager.Accounts.get_user(user.id) == nil
    end
  end

  test "sign_out requires valid csrf token", %{conn: conn} do
    user = user_fixture()
    conn = auth_conn(conn, user)
    conn = put_req_header(conn, "x-xsrf-token", "wrong-token")

    conn = post(conn, ~p"/api/auth/sign_out")
    assert json_response(conn, 403)["error"] == "Invalid CSRF token"
  end

  defp auth_conn(conn, %User{} = user) do
    conn
    |> Plug.Test.init_test_session(%{user_id: user.id, csrf_token: "test-token"})
    |> put_req_header("x-xsrf-token", "test-token")
  end

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end
end
