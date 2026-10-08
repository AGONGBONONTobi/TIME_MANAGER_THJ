defmodule TimeManager.Clocking.ClockCorrection do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clock_corrections" do
    field :proposed_time, :utc_datetime
    field :proposed_status, :boolean
    field :reason, :string
    field :status, :string, default: "pending" # pending, approved, rejected
    field :reviewed_at, :utc_datetime

    belongs_to :user, TimeManager.Accounts.User
    belongs_to :original_clock, TimeManager.Clocking.Clock
    belongs_to :reviewed_by, TimeManager.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(clock_correction, attrs) do
    clock_correction
    |> cast(attrs, [:proposed_time, :proposed_status, :reason, :user_id, :original_clock_id])
    |> validate_required([:proposed_time, :proposed_status, :reason, :user_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:original_clock_id)
  end

  def review_changeset(clock_correction, attrs) do
    clock_correction
    |> cast(attrs, [:status, :reviewed_by_id, :reviewed_at])
    |> validate_required([:status, :reviewed_by_id, :reviewed_at])
    |> validate_inclusion(:status, ["approved", "rejected"])
    |> foreign_key_constraint(:reviewed_by_id)
  end
end
