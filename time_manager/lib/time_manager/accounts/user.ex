defmodule TimeManager.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :role, :string, default: "employee"

    timestamps(type: :utc_datetime)
    has_many :clocks, TimeManager.Clocking.Clock, on_delete: :delete_all
    has_many :workingtimes, TimeManager.WorkingTimes.WorkingTime, on_delete: :delete_all
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password, :role])
    |> validate_required([:username, :email])
    |> validate_length(:password, min: 8)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
    |> validate_inclusion(:role, ["employee", "manager", "admin"])
    |> unique_constraint(:email)
    |> hash_password()
  end

  def registration_changeset(user, attrs) do
    changeset =
      user
      |> cast(attrs, [:username, :email, :password, :role])
      |> validate_required([:username, :email, :password])
      |> validate_length(:password, min: 8)
      |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
      |> validate_inclusion(:role, ["employee", "manager", "admin"])
      |> unique_constraint(:email)

    changeset
    |> put_change(:role, get_field(changeset, :role) || "employee")
    |> hash_password()
  end

  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset

      password ->
        put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
    end
  end
end
