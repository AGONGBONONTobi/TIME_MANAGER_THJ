defmodule TimeManager.WorkPolicies.WorkPolicy do
  use Ecto.Schema
  import Ecto.Changeset

  schema "work_policies" do
    field :name, :string
    field :weekly_hours, :decimal
    field :work_days, :integer
    field :night_start, :time
    field :night_end, :time
    field :overtime_threshold, :decimal
    field :active, :boolean, default: true
    timestamps(type: :utc_datetime)
  end

  def changeset(policy, attrs) do
    policy
    |> cast(attrs, [:name, :weekly_hours, :work_days, :night_start, :night_end, :overtime_threshold, :active])
    |> validate_required([:name, :weekly_hours, :work_days, :night_start, :night_end, :overtime_threshold])
    |> validate_number(:weekly_hours, greater_than: 0)
    |> validate_number(:work_days, greater_than: 0, less_than_or_equal_to: 7)
    |> validate_number(:overtime_threshold, greater_than: 0)
    |> unique_constraint(:name)
  end
end