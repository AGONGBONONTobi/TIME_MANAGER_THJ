defmodule TimeManager.WorkingTimes.WorkingTime do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workingtimes" do
    field(:start_at, :utc_datetime)
    field(:end_at, :utc_datetime)

    belongs_to(:user, TimeManager.Accounts.User)
    # field(:user, :id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(working_time, attrs) do
    working_time
    |> cast(attrs, [:start_at, :end_at, :user_id])
    |> validate_required([:start_at, :user_id])
    # |> validate_required([:start_at, :end_at, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
