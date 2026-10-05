defmodule TimeManagerWeb.NotificationController do
  use TimeManagerWeb, :controller

  alias TimeManager.Notifications

  def index(conn, _params), do: json(conn, %{data: Enum.map(Notifications.list_for_user(conn.assigns.current_user.id), &data/1)})

  def read(conn, %{"id" => id}) do
    case Notifications.mark_read(id, conn.assigns.current_user.id) do
      {:ok, notification} -> json(conn, %{data: data(notification)})
      {:error, :not_found} -> send_resp(conn, :not_found, "")
    end
  end

  defp data(notification), do: %{id: notification.id, user_id: notification.user_id, type: notification.type, message: notification.message, read_at: notification.read_at, inserted_at: notification.inserted_at}
end
