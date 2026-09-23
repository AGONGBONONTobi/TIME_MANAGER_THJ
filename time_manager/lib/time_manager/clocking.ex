defmodule TimeManager.Clocking do
  @moduledoc """
  Contexte métier pour la gestion des pointages (clocks).
  """

  import Ecto.Query
  alias TimeManager.Repo
  alias TimeManager.Clocking.Clock
  alias TimeManager.Accounts.User
  alias TimeManager.WorkingTimes.WorkingTime

  @doc """
  Liste tous les clocks d'un utilisateur, du plus récent au plus ancien.

  ## Exemples

      iex> list_clocks(1)
      [%Clock{}, ...]
  """
  def list_clocks(user_id) do
    Clock
    |> where([c], c.user_id == ^user_id)
    |> order_by([c], desc: c.time)
    |> Repo.all()
  end

  def get_last_clock(user_id) do
    Clock
    |> where([c], c.user_id == ^user_id)
    |> order_by([c], desc: c.time)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Crée un nouveau clock pour un utilisateur.

  Le `status` est déterminé automatiquement :
  - `true` (arrivée / clock-in) si aucun clock précédent OU dernier = départ
  - `false` (départ / clock-out) si dernier = arrivée

  Le `time` est rempli avec l'heure UTC actuelle.
  Lève `Ecto.NoResultsError` si l'utilisateur n'existe pas.
  """
  def create_clock(user_id) do
    case Repo.get(User, user_id) do
      nil ->
        {:error, :user_not_found}

      user ->
        time = DateTime.utc_now() |> DateTime.truncate(:second)
        status = user_id |> get_last_clock() |> determine_status()

        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          :clock,
          Clock.changeset(%Clock{}, %{user_id: user.id, time: time, status: status})
        )
        |> Ecto.Multi.run(:working_time, fn repo, _changes ->
          sync_working_time(repo, user.id, status, time)
        end)
        |> Repo.transaction()
        |> case do
          {:ok, %{clock: clock}} -> {:ok, clock}
          {:error, _step, reason, _changes} -> {:error, reason}
        end
    end
  end

  defp sync_working_time(repo, user_id, true, time) do
    if repo.exists?(from w in WorkingTime, where: w.user_id == ^user_id and is_nil(w.end)) do
      {:error, :already_clocked_in}
    else
      %WorkingTime{}
      |> WorkingTime.changeset(%{user_id: user_id, start: time})
      |> repo.insert()
    end
  end

  defp sync_working_time(repo, user_id, false, time) do
    case repo.one(
           from w in WorkingTime,
             where: w.user_id == ^user_id and is_nil(w.end),
             order_by: [desc: w.start],
             limit: 1
         ) do
      nil -> {:error, :not_clocked_in}
      working_time -> working_time |> WorkingTime.changeset(%{end: time}) |> repo.update()
    end
  end

  defp determine_status(nil), do: true
  defp determine_status(%Clock{status: true}), do: false
  defp determine_status(%Clock{status: false}), do: true
end
