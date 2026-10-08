defmodule TimeManager.WorkingTimes.WorkingTime do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workingtimes" do
    field(:start, :utc_datetime)
    field(:end, :utc_datetime)
    field(:break_duration, :integer, default: 0)
    field(:deleted_at, :utc_datetime)

    belongs_to(:user, TimeManager.Accounts.User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(working_time, attrs) do
    working_time
    |> cast(attrs, [:start, :end, :user_id, :break_duration])
    |> validate_required([:start, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
