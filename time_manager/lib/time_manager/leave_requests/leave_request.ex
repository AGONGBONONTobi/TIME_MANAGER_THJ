defmodule TimeManager.LeaveRequests.LeaveRequest do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending approved rejected)

  schema "leave_requests" do
    field :type, :string
    field :start_date, :date
    field :end_date, :date
    field :reason, :string
    field :status, :string, default: "pending"
    field :reviewed_at, :utc_datetime
    belongs_to :user, TimeManager.Accounts.User
    belongs_to :reviewed_by, TimeManager.Accounts.User
    timestamps(type: :utc_datetime)
  end

  def changeset(request, attrs) do
    request
    |> cast(attrs, [:type, :start_date, :end_date, :reason, :user_id])
    |> validate_required([:type, :start_date, :end_date, :user_id])
    |> validate_date_order()
    |> foreign_key_constraint(:user_id)
  end

  def review_changeset(request, attrs) do
    request
    |> cast(attrs, [:status, :reviewed_by_id, :reviewed_at])
    |> validate_required([:status, :reviewed_by_id, :reviewed_at])
    |> validate_inclusion(:status, @statuses -- ["pending"])
    |> foreign_key_constraint(:reviewed_by_id)
  end

  defp validate_date_order(changeset) do
    validate_change(changeset, :end_date, fn :end_date, end_date ->
      start_date = get_field(changeset, :start_date)
      if start_date && Date.compare(end_date, start_date) == :lt, do: [end_date: "must be on or after start date"], else: []
    end)
  end
end