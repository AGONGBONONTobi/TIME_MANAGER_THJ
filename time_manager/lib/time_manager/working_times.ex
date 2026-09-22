defmodule TimeManager.WorkingTimes do
  @moduledoc """
  The WorkingTimes context.
  """

  import Ecto.Query, warn: false
  alias TimeManager.Repo

  alias TimeManager.WorkingTimes.WorkingTime

  def list_workingtimes do
    Repo.all(WorkingTime)
  end

  def get_working_time!(id), do: Repo.get!(WorkingTime, id)

  def get_working_time(id), do: Repo.get(WorkingTime, id)

  # ⬇️ FONCTIONS AJOUTÉES POUR LE CONTRÔLEUR

  @doc """
  Récupère un workingtime d'un user précis.
  Raise si pas trouvé.
  """
  def get_for_user!(user_id, id) do
    WorkingTime
    |> where([w], w.id == ^id and w.user_id == ^user_id)
    |> Repo.one!()
  end

  @doc """
  Liste les workingtimes d'un user, filtrés par plage de dates.
  """
  defp parse_datetime(str) do
    # Remplace l'espace par T pour ISO 8601
    str_normalized = String.replace(str, " ", "T")

    case NaiveDateTime.from_iso8601(str_normalized) do
      {:ok, dt} -> dt
      _ -> nil
    end
  end

  def list_for_user(user_id, start_date \\ nil, end_date \\ nil) do
    query = from w in WorkingTime, where: w.user_id == ^user_id

    query =
      case start_date && parse_datetime(start_date) do
        nil -> query
        dt -> where(query, [w], w.start_at >= ^dt)
      end

    query =
      case end_date && parse_datetime(end_date) do
        nil -> query
        dt -> where(query, [w], w.end_at <= ^dt)
      end

    Repo.all(query)
  end
  @doc """
  Enregistre un nouveau workingtime (clock in).
  Crée un workingtime avec start_at = maintenant.
  """
  def clock_in(user_id) do
    create_working_time(%{
      "user_id" => user_id,
      "start_at" => NaiveDateTime.utc_now()
    })
  end

  # ⬆️ FIN DES AJOUTS

  def create_working_time(attrs \\ %{}) do
    %WorkingTime{}
    |> WorkingTime.changeset(attrs)
    |> Repo.insert()
  end

  def update_working_time(%WorkingTime{} = working_time, attrs) do
    working_time
    |> WorkingTime.changeset(attrs)
    |> Repo.update()
  end

  def delete_working_time(%WorkingTime{} = working_time) do
    Repo.delete(working_time)
  end

  def change_working_time(%WorkingTime{} = working_time, attrs \\ %{}) do
    WorkingTime.changeset(working_time, attrs)
  end
end