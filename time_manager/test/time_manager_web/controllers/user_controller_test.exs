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
               item["id"] == user.id and item["email"] == user.email and
                 item["username"] == user.username
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
    test "requires an administrator", %{conn: conn} do
      conn = post(conn, ~p"/api/users", user: @create_attrs)
      assert json_response(conn, 401)["error"] == "Authentication required"

      employee = user_fixture()

      conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> auth_conn(employee)

      conn = post(conn, ~p"/api/users", user: @create_attrs)
      assert json_response(conn, 403)["error"] == "Insufficient permissions"
    end

    test "creates a user with a one-time temporary password", %{conn: conn} do
      admin = user_fixture(%{role: "admin"})
      conn = auth_conn(conn, admin)
      attrs = Map.put(@create_attrs, :password, "attacker-chosen-password")
      conn = post(conn, ~p"/api/users", user: attrs)

      assert %{
               "data" => %{
                 "id" => id,
                 "email" => "someemail-authenticated@gmail.com",
                 "username" => "some username",
                 "must_change_password" => true
               },
               "temporary_password" => temporary_password
             } = json_response(conn, 201)

      assert String.length(temporary_password) >= 32
      created_user = TimeManager.Accounts.get_user(id)
      assert created_user.must_change_password

      assert {:ok, authenticated_user} =
               TimeManager.Accounts.authenticate(created_user.email, temporary_password)

      assert authenticated_user.id == created_user.id

      assert {:error, :invalid_credentials} =
               TimeManager.Accounts.authenticate(created_user.email, "attacker-chosen-password")
    end

    test "renders errors when data is invalid", %{conn: conn} do
      admin = user_fixture(%{role: "admin"})
      conn = auth_conn(conn, admin)
      conn = post(conn, ~p"/api/users", user: @invalid_attrs)
      assert json_response(conn, 400)["error"] != %{}
    end
  end

  test "public account registration endpoint is unavailable", %{conn: conn} do
    conn =
      post(conn, "/api/auth/sign_up", %{
        username: "Public",
        email: "public@example.com",
        password: "password123"
      })

    assert response(conn, 404)
  end

  test "temporary-password users cannot use protected APIs until changing their password", %{
    conn: conn
  } do
    {:ok, user, temporary_password} =
      TimeManager.Accounts.create_user_with_temporary_password(%{
        "username" => "First login",
        "email" => "first-login-#{System.unique_integer([:positive])}@example.com",
        "role" => "employee"
      })

    conn = auth_conn(conn, user)
    conn = get(conn, ~p"/api/users")

    assert %{"code" => "password_change_required"} = json_response(conn, 403)

    rejected_password_conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> auth_conn(user)
      |> put(~p"/api/auth/password", %{
        current_password: temporary_password,
        new_password: "too-short"
      })

    assert response(rejected_password_conn, 422)
    assert TimeManager.Accounts.get_user!(user.id).must_change_password

    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> auth_conn(user)
      |> put(~p"/api/auth/password", %{
        current_password: temporary_password,
        new_password: "new-secure-password-123"
      })

    assert %{"user" => %{"must_change_password" => false}} = json_response(conn, 200)
    refute TimeManager.Accounts.get_user!(user.id).must_change_password
  end

  describe "update user" do
    setup [:create_user]

    test "non-admin users cannot modify account privileges or update other users", %{
      conn: conn,
      user: user
    } do
      conn = auth_conn(conn, user)
      conn = put(conn, ~p"/api/users/#{user}", user: %{role: "admin"})
      assert json_response(conn, 403)["error"] =~ "Only administrators"

      conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> auth_conn(user)
        |> put(~p"/api/users/#{user}", user: %{password: "new-secure-password-123"})

      assert json_response(conn, 403)["error"] =~ "Only administrators"

      other_user = user_fixture(%{email: "another-user@example.com"})

      conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> auth_conn(user)
        |> put(~p"/api/users/#{other_user}", user: @update_attrs)

      assert json_response(conn, 403)["error"] == "You cannot access another user's data"
    end

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

  # defp auth_conn(conn, %User{} = user) do
  #   conn
  #   |> Plug.Test.init_test_session(%{user_id: user.id, csrf_token: "test-token"})
  #   |> put_req_header("x-xsrf-token", "test-token")
  # end

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end
end
