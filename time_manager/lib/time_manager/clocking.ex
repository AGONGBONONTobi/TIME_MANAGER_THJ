defmodule TimeManager.Clocking do
  @moduledoc """
  Contexte métier pour la gestion des pointages (clocks).
  """

  import Ecto.Query
  alias TimeManager.Repo
  alias TimeManager.Clocking.Clock
  alias TimeManager.Accounts.User
  alias TimeManager.WorkingTimes.WorkingTime

  def list_clocks(user_id) do
    Clock
    |> where([c], c.user_id == ^user_id and is_nil(c.deleted_at))
    |> order_by([c], desc: c.id)
    |> Repo.all()
  end

  def get_last_clock(user_id) do
    Clock
    |> where([c], c.user_id == ^user_id and is_nil(c.deleted_at))
    |> order_by([c], desc: c.id)
    |> limit(1)
    |> Repo.one()
  end

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

  # CLOCK IN : crée un workingtime si pas déjà en cours
  defp sync_working_time(repo, user_id, true, time) do
    if repo.exists?(from w in WorkingTime, where: w.user_id == ^user_id and is_nil(w.end)) do
      {:error, :already_clocked_in}
    else
      %WorkingTime{}
      |> WorkingTime.changeset(%{user_id: user_id, start: time})
      |> repo.insert()
    end
  end

  # CLOCK OUT : ferme le workingtime en cours
  defp sync_working_time(repo, user_id, false, time) do
    case repo.one(
           from w in WorkingTime,
             where: w.user_id == ^user_id and is_nil(w.end),
             order_by: [desc: w.start],
             limit: 1
         ) do
      nil ->
        {:error, :not_clocked_in}

      working_time ->
        working_time
        |> WorkingTime.changeset(%{end: time})
        |> repo.update()
    end
  end

  defp determine_status(nil), do: true
  defp determine_status(%Clock{status: true}), do: false
  defp determine_status(%Clock{status: false}), do: true

  # ═══════════════════════════════════════════════════════
  # CLOCK CORRECTIONS
  # ═══════════════════════════════════════════════════════

  alias TimeManager.Clocking.ClockCorrection

  def list_clock_corrections(user_id) do
    ClockCorrection
    |> where([c], c.user_id == ^user_id)
    |> order_by([c], desc: c.inserted_at)
    |> Repo.all()
  end

  def list_pending_clock_corrections do
    ClockCorrection
    |> where([c], c.status == "pending")
    |> order_by([c], desc: c.inserted_at)
    |> Repo.all()
  end

  def get_clock_correction!(id), do: Repo.get!(ClockCorrection, id)

  def create_clock_correction(attrs \\ %{}) do
    %ClockCorrection{}
    |> ClockCorrection.changeset(attrs)
    |> Repo.insert()
  end

  def approve_clock_correction(id, manager_id) do
    case Repo.get(ClockCorrection, id) do
      nil ->
        {:error, :not_found}

      correction ->
        Ecto.Multi.new()
        |> Ecto.Multi.update(
          :correction,
          ClockCorrection.review_changeset(correction, %{
            status: "approved",
            reviewed_by_id: manager_id,
            reviewed_at: DateTime.utc_now() |> DateTime.truncate(:second)
          })
        )
        |> Ecto.Multi.run(:soft_delete_old_clock, fn repo, _changes ->
          if correction.original_clock_id do
            old_clock = repo.get!(Clock, correction.original_clock_id)
            repo.update(Ecto.Changeset.change(old_clock, deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)))
          else
            {:ok, nil}
          end
        end)
        |> Ecto.Multi.insert(:new_clock, fn _changes ->
          Clock.changeset(%Clock{}, %{
            user_id: correction.user_id,
            time: correction.proposed_time,
            status: correction.proposed_status
          })
        end)
        |> Repo.transaction()
        |> case do
          {:ok, %{correction: updated_correction}} -> {:ok, updated_correction}
          {:error, _step, reason, _changes} -> {:error, reason}
        end
    end
  end

  def reject_clock_correction(id, manager_id) do
    case Repo.get(ClockCorrection, id) do
      nil ->
        {:error, :not_found}

      correction ->
        correction
        |> ClockCorrection.review_changeset(%{
          status: "rejected",
          reviewed_by_id: manager_id,
          reviewed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })
        |> Repo.update()
    end
  end
end