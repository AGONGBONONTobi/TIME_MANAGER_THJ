defmodule TimeManagerWeb.UserController do
  use TimeManagerWeb, :controller

  alias TimeManager.Accounts

  action_fallback TimeManagerWeb.FallbackController

  def index(conn, params) do
    users = Accounts.get_users_by_filters(params)

    conn
    |> put_status(200)
    |> render(:index, users: users)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_status(201)
        |> render(:show, user: user)

      {:error, _changeset} ->
        conn
        |> put_status(400)
        |> json(%{error: "Failed to create user"})
    end
  end

  def show(conn, %{"userID" => id}) do
    case Accounts.get_user(id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "User not found"})

      user ->
        conn
        |> put_status(200)
        |> render(:show, user: user)
    end
  end

  def update(conn, %{"userID" => id, "user" => user_params}) do
    case Accounts.get_user(id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "User not found"})

      user ->
        case Accounts.update_user(user, user_params) do
          {:ok, updated_user} ->
            conn
            |> put_status(200)
            |> render(:show, user: updated_user)

          {:error, _changeset} ->
            conn
            |> put_status(400)
            |> json(%{error: "Failed to update user"})
        end
    end
  end

  def delete(conn, %{"userID" => id}) do
    case Accounts.get_user(id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "User not found"})

      user ->
        Accounts.delete_user(user)
        send_resp(conn, :no_content, "")
    end
  end
end
