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

  def get_users_by_filters(params) do
    query = from u in User

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
end
