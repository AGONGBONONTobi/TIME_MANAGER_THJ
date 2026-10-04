defmodule TimeManager.Teams.TeamMembership do
  use Ecto.Schema
  import Ecto.Changeset

  schema "team_memberships" do
    field :active, :boolean, default: true
    belongs_to :team, TimeManager.Teams.Team
    belongs_to :user, TimeManager.Accounts.User
    timestamps(type: :utc_datetime)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:team_id, :user_id, :active])
    |> validate_required([:team_id, :user_id])
    |> unique_constraint([:team_id, :user_id])
  end
end