defmodule TimeManager.Notifications do
  import Ecto.Query, warn: false
  alias TimeManager.Repo
  alias TimeManager.Notifications.Notification

  def list_for_user(user_id), do: Repo.all(from n in Notification, where: n.user_id == ^user_id, order_by: [desc: n.inserted_at])

  def create(attrs), do: %Notification{} |> Notification.changeset(attrs) |> Repo.insert()

  def remind_about_clock(user_id, _manager_id) do
    create(%{user_id: user_id, type: "clock_reminder", message: "Votre manager vous demande de vérifier votre pointage."})
  end

  def mark_read(id, user_id) do
    case Repo.get_by(Notification, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      notification -> notification |> Notification.read_changeset() |> Repo.update()
    end
  end
end
