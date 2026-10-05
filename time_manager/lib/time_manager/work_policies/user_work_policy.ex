defmodule TimeManager.WorkPolicies.UserWorkPolicy do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_work_policies" do
    field :starts_on, :date
    field :ends_on, :date
    belongs_to :user, TimeManager.Accounts.User
    belongs_to :policy, TimeManager.WorkPolicies.WorkPolicy
    timestamps(type: :utc_datetime)
  end

  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:user_id, :policy_id, :starts_on, :ends_on])
    |> validate_required([:user_id, :policy_id, :starts_on])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:policy_id)
  end
end