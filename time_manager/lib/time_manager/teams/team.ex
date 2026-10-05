defmodule TimeManager.Teams.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string
    field :description, :string
    belongs_to :manager, TimeManager.Accounts.User
    has_many :memberships, TimeManager.Teams.TeamMembership
    has_many :members, through: [:memberships, :user]
    timestamps(type: :utc_datetime)
  end

  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :description, :manager_id])
    |> validate_required([:name, :manager_id])
    |> unique_constraint(:name)
    |> foreign_key_constraint(:manager_id)
  end
end