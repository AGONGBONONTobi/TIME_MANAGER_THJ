defmodule TimeManager.Clocking.Clock do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clocks" do
    field :status, :boolean
    field :time, :utc_datetime
    field :client_event_id, :string
    field :source, :string, default: "web"
    field :received_at, :utc_datetime
    belongs_to :user, TimeManager.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(clock, attrs) do
    clock
    |> cast(attrs, [:time, :status, :user_id, :client_event_id, :source, :received_at])
    |> validate_required([:time, :status, :user_id])
    |> unique_constraint(:client_event_id)
    |> assoc_constraint(:user)
  end
end
