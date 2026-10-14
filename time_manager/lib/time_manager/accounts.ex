defmodule TimeManager.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias TimeManager.Repo

  alias TimeManager.Accounts.User

  def list_users do
    Repo.all(User)
  end

  def list_users_of_manager(manager_id) do
    from(u in User,
      join: tm in TimeManager.Teams.TeamMembership,
      on: tm.user_id == u.id,
      join: t in TimeManager.Teams.Team,
      on: t.id == tm.team_id and t.manager_id == ^manager_id,
      where: tm.active == true,
      select: u,
      distinct: true
    )
    |> Repo.all()
  end

  def mark_onboarded(user) do
    user
    |> Ecto.Changeset.change(onboarded_at: DateTime.utc_now() |> DateTime.truncate(:second))
    |> Repo.update()
  end

  def get_users_by_filters(params) do
    query = from(u in User)

    query =
      if params["email"],
        do: where(query, [u], u.email == ^params["email"]),
        else: query

    query =
      if params["username"],
        do: where(query, [u], u.username == ^params["username"]),
        else: query

    Repo.all(query)
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_user(id), do: Repo.get(User, id)

  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def create_user_with_temporary_password(attrs) do
    temporary_password = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

    changeset =
      %User{}
      |> User.changeset(Map.put(attrs, "password", temporary_password))
      |> Ecto.Changeset.put_change(:must_change_password, true)

    case Repo.insert(changeset) do
      {:ok, user} -> {:ok, user, temporary_password}
      error -> error
    end
  end

  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def authenticate(email, password) do
    with %User{} = user <- get_user_by_email(email),
         true <- valid_password?(user, password) do
      {:ok, user}
    else
      _ -> {:error, :invalid_credentials}
    end
  end

  def valid_password?(%User{} = user, password) do
    case user.password_hash do
      nil -> false
      hash -> Bcrypt.verify_pass(password, hash)
    end
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def change_password(%User{} = user, current_password, new_password) do
    if valid_password?(user, current_password) do
      user
      |> User.changeset(%{password: new_password})
      |> Ecto.Changeset.put_change(:must_change_password, false)
      |> Repo.update()
    else
      {:error, :invalid_current_password}
    end
  end
end
