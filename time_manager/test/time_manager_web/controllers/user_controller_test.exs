defmodule TimeManagerWeb.UserControllerTest do
  use TimeManagerWeb.ConnCase

  import TimeManager.AccountsFixtures


  @create_attrs %{
    username: "some username",
    email: "someemail@gmail.com"
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
    test "lists all users", %{conn: conn} do
      conn = get(conn, ~p"/api/users")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "show user" do
    setup do
      {:ok, %User{} = user} = TimeManager.Accounts.create_user(%{username: "Tobi", email: "test@gmail.com"})
      %{user: user}
    end

    test "renders user when id data is valid", %{conn: conn, user: user} do
      conn = get(conn, ~p"/api/users/#{user.id}")
      assert %{"id" => id} = json_response(conn, 200)["data"]
    end
    test "render errors when user not found", %{conn: conn, user: user} do 
      conn = get(conn, ~p"/api/users/258")
      assert json_response(conn, 404)["error"] == "User not found"
    end
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/users", user: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/users/#{id}")

      assert %{
               "id" => ^id,
               "email" => "someemail@gmail.com",
               "username" => "some username"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/users", user: @invalid_attrs)
      assert json_response(conn, 400)["error"] != %{}
    end
  end

  describe "update user" do
    setup [:create_user]

    test "renders user when data is valid", %{conn: conn, user: %User{id: id} = user} do
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
      conn = put(conn, ~p"/api/users/#{user}", user: @invalid_attrs)
      assert json_response(conn, 400)["error"] != %{}
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(conn, ~p"/api/users/#{user}")
      assert response(conn, 204)

      conn = get(conn, ~p"/api/users/#{user}")
      assert json_response(conn, 404)["error"] != %{}
    end
  end

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end
end
