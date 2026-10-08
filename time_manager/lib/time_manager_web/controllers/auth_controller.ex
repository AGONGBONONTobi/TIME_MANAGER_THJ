defmodule TimeManagerWeb.AuthController do
  use TimeManagerWeb, :controller

  alias TimeManager.Accounts

  def sign_up(conn, params) do
    case Accounts.register_user(params) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{user: public_user(user)})

      {:error, changeset} ->
        message =
          case changeset.errors do
            [{:email, {"has already been taken", _}} | _] -> "Email déjà utilisé."
            _ -> "Données invalides."
          end

        conn
        |> put_status(:bad_request)
        |> json(%{error: message})
    end
  end

  def sign_in(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate(email, password) do
      {:ok, user} ->
        csrf_token = generate_csrf_token()

        {:ok, jwt, _claims} =
          TimeManager.Token.generate_and_sign(%{
            "user_id" => user.id,
            "role" => user.role,
            "csrf_token" => csrf_token
          })

        conn
        |> put_resp_cookie("auth_token", jwt,
          http_only: true,
          secure: false,
          same_site: "Lax",
          path: "/"
        )
        |> put_resp_cookie("c-xsrf-token", csrf_token,
          http_only: false,
          secure: false,
          same_site: "Lax",
          path: "/"
        )
        |> put_status(:ok)
        |> json(%{user: public_user(user), token: jwt})

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Identifiants invalides."})
    end
  end

  def sign_out(conn, _params) do
    conn
    |> delete_resp_cookie("auth_token", path: "/")
    |> delete_resp_cookie("c-xsrf-token", path: "/")
    |> put_status(:ok)
    |> json(%{ok: true})
  end

  def me(conn, _params) do
    json(conn, %{user: public_user(conn.assigns.current_user)})
  end

  defp public_user(user) do
    %{
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role
    }
  end

  defp generate_csrf_token do
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64(padding: false)
  end
end
