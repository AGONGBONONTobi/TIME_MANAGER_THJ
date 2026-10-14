defmodule TimeManagerWeb.UserController do
  use TimeManagerWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias TimeManager.Accounts

  action_fallback TimeManagerWeb.FallbackController

  operation(:index,
    summary: "List users",
    responses: [ok: "Users returned"]
  )

  operation(:create,
    summary: "Create a user",
    responses: [created: "User created", bad_request: "Invalid user"]
  )

  operation(:show,
    summary: "Get a user",
    parameters: [userID: [in: :path, required: true, type: :string]],
    responses: [ok: "User returned", not_found: "User not found"]
  )

  operation(:update,
    summary: "Update a user",
    parameters: [userID: [in: :path, required: true, type: :string]],
    responses: [ok: "User updated", bad_request: "Invalid user", not_found: "User not found"]
  )

  operation(:delete,
    summary: "Delete a user",
    parameters: [userID: [in: :path, required: true, type: :string]],
    responses: [no_content: "User deleted", not_found: "User not found"]
  )

  def index(conn, params) do
    current = conn.assigns.current_user

    users =
      case current.role do
        "admin" ->
          Accounts.get_users_by_filters(params)

        "manager" ->
          Accounts.list_users_of_manager(current.id)
          |> filter_by_params(params)

        _ ->
          [current]
      end

    conn
    |> put_status(200)
    |> json(%{data: Enum.map(users, &public_user/1)})
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user_with_temporary_password(user_params) do
      {:ok, user, temporary_password} ->
        conn
        |> put_status(201)
        |> json(%{
          data: %{
            id: user.id,
            username: user.username,
            email: user.email,
            role: user.role,
            status: user.status,
            must_change_password: user.must_change_password
          },
          temporary_password: temporary_password
        })

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
    protected_fields = ["role", "status", "password", "contract_start", "contract_end"]

    non_admin_changes? =
      conn.assigns.current_user.role != "admin" and
        Enum.any?(protected_fields, fn field ->
          Map.has_key?(user_params, field) or
            Map.has_key?(user_params, String.to_existing_atom(field))
        end)

    if non_admin_changes? do
      conn
      |> put_status(:forbidden)
      |> json(%{
        error:
          "Only administrators can update account privileges, passwords, and lifecycle fields"
      })
    else
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

  operation(:update_role,
    summary: "Update user role (Admin only)",
    parameters: [userID: [in: :path, required: true, type: :string]],
    responses: [ok: "Role updated", bad_request: "Invalid role", not_found: "User not found"]
  )

  def update_role(conn, %{"userID" => id, "role" => role}) do
    case Accounts.get_user(id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "User not found"})

      user ->
        if role in ["employee", "manager", "admin"] do
          case Accounts.update_user(user, %{"role" => role}) do
            {:ok, updated_user} ->
              conn
              |> put_status(200)
              |> render(:show, user: updated_user)

            {:error, _changeset} ->
              conn
              |> put_status(400)
              |> json(%{error: "Failed to update role"})
          end
        else
          conn
          |> put_status(400)
          |> json(%{error: "Invalid role"})
        end
    end
  end

  defp filter_by_params(users, params) do
    Enum.filter(users, fn user ->
      matches? = true

      matches? =
        if params["email"], do: user.email == params["email"] and matches?, else: matches?

      matches? =
        if params["username"],
          do: user.username == params["username"] and matches?,
          else: matches?

      matches?
    end)
  end

  defp public_user(user) do
    %{
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
      status: user.status,
      contract_start: user.contract_start,
      contract_end: user.contract_end,
      onboarded_at: user.onboarded_at
    }
  end
end
