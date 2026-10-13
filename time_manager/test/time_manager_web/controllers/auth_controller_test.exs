defmodule TimeManagerWeb.AuthControllerTest do
  use TimeManagerWeb.ConnCase

  alias TimeManager.Accounts
  alias TimeManager.Token

  setup do
    email = "mobile-login-#{System.unique_integer([:positive])}@example.com"

    {:ok, user} =
      Accounts.register_user(%{
        username: "Mobile employee",
        email: email,
        password: "test-password-123"
      })

    %{user: user}
  end

  test "returns bearer credentials to the trusted Cordova origin", %{conn: conn, user: user} do
    conn =
      conn
      |> put_req_header("origin", "https://localhost")
      |> post(~p"/api/auth/sign_in", %{email: user.email, password: "test-password-123"})

    assert %{
             "user" => %{
               "id" => id,
               "role" => "employee",
               "must_change_password" => false
             },
             "token" => token,
             "csrf_token" => csrf_token
           } = json_response(conn, 200)

    assert id == user.id
    assert {:ok, %{"csrf_token" => ^csrf_token}} = Token.verify_and_validate(token)
  end

  test "does not expose bearer credentials to browser clients", %{conn: conn, user: user} do
    conn = post(conn, ~p"/api/auth/sign_in", %{email: user.email, password: "test-password-123"})
    body = json_response(conn, 200)

    assert %{"user" => %{"id" => id}} = body
    assert id == user.id
    refute Map.has_key?(body, "token")
    refute Map.has_key?(body, "csrf_token")
  end
end
