defmodule TimeManager.Notifications do
  import Ecto.Query, warn: false
  require Logger
  alias TimeManager.Repo
  alias TimeManager.Notifications.Notification

  def list_for_user(user_id),
    do:
      Repo.all(
        from n in Notification, where: n.user_id == ^user_id, order_by: [desc: n.inserted_at]
      )

  def create(attrs), do: %Notification{} |> Notification.changeset(attrs) |> Repo.insert()

  def remind_about_clock(user_id, _manager_id) do
    create(%{
      user_id: user_id,
      type: "clock_reminder",
      message: "Votre manager vous demande de vérifier votre pointage."
    })
  end

  def notify_task_created(team, task, creator_id) do
    team.memberships
    |> Enum.map(& &1.user_id)
    |> Enum.reject(&(&1 == creator_id))
    |> notify_all("new_task", "Une nouvelle tâche a été ajoutée à votre équipe : #{task.title}.")
  end

  def notify_team_added(user_id, team) do
    notify_once(user_id, "team_added", "Vous avez été ajouté à l'équipe #{team.name}.")
  end

  def notify_leave_review(user_id, status, reviewer_name) do
    label = if status == "approved", do: "approuvée", else: "refusée"

    notify_once(
      user_id,
      "leave_review",
      "Votre demande de congé a été #{label} par #{reviewer_name}."
    )
  end

  def notify_clock_correction_review(user_id, status, reviewer_name) do
    label = if status == "approved", do: "approuvée", else: "refusée"

    notify_once(
      user_id,
      "timesheet_review",
      "Votre correction de timesheet a été #{label} par #{reviewer_name}."
    )
  end

  def notify_night_threshold(user_id, night_count, week_start) when night_count > 3 do
    message = "Vous avez fait #{night_count} nuits cette semaine (seuil : 3)."

    case Repo.exists?(
           from n in Notification,
             where:
               n.user_id == ^user_id and n.type == "night_threshold" and
                 n.inserted_at >= ^week_start
         ) do
      false -> create_and_log(%{user_id: user_id, type: "night_threshold", message: message})
      true -> :ok
    end
  end

  def notify_night_threshold(_user_id, _night_count, _week_start), do: :ok

  def mark_read(id, user_id) do
    case Repo.get_by(Notification, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      notification -> notification |> Notification.read_changeset() |> Repo.update()
    end
  end

  defp notify_all(user_ids, type, message) do
    Enum.each(user_ids, fn user_id ->
      create_and_log(%{user_id: user_id, type: type, message: message})
    end)

    :ok
  end

  defp notify_once(user_id, type, message) do
    case Repo.exists?(
           from n in Notification,
             where: n.user_id == ^user_id and n.type == ^type and n.message == ^message
         ) do
      false -> create_and_log(%{user_id: user_id, type: type, message: message})
      true -> :ok
    end
  end

  defp create_and_log(attrs) do
    case create(attrs) do
      {:ok, _notification} ->
        :ok

      {:error, reason} ->
        Logger.error("Notification creation failed: #{inspect(reason)}")
        :error
    end
  end
end
