defmodule TimeManager.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications" do
    field :type, :string
    field :message, :string
    field :read_at, :utc_datetime
    belongs_to :user, TimeManager.Accounts.User
    timestamps(type: :utc_datetime)
  end

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:user_id, :type, :message])
    |> validate_required([:user_id, :type, :message])
    |> foreign_key_constraint(:user_id)
  end

  def read_changeset(notification) do
    change(notification, read_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end
end
