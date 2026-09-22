defmodule TimeManager.WorkingTimes do
  @moduledoc """
  The WorkingTimes context.
  """

  import Ecto.Query, warn: false
  alias TimeManager.Repo

  alias TimeManager.WorkingTimes.WorkingTime

  @doc """
  Returns the list of workingtimes.

  ## Examples

      iex> list_workingtimes()
      [%WorkingTime{}, ...]

  """
  def list_workingtimes do
    Repo.all(WorkingTime)
  end

  @doc """
  Gets a single working_time.

  Raises `Ecto.NoResultsError` if the Working time does not exist.

  ## Examples

      iex> get_working_time!(123)
      %WorkingTime{}

      iex> get_working_time!(456)
      ** (Ecto.NoResultsError)

  """
  def get_working_time!(id), do: Repo.get!(WorkingTime, id)

  @doc """
  Creates a working_time.

  ## Examples

      iex> create_working_time(%{field: value})
      {:ok, %WorkingTime{}}

      iex> create_working_time(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_working_time(attrs \\ %{}) do
    %WorkingTime{}
    |> WorkingTime.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a working_time.

  ## Examples

      iex> update_working_time(working_time, %{field: new_value})
      {:ok, %WorkingTime{}}

      iex> update_working_time(working_time, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_working_time(%WorkingTime{} = working_time, attrs) do
    working_time
    |> WorkingTime.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a working_time.

  ## Examples

      iex> delete_working_time(working_time)
      {:ok, %WorkingTime{}}

      iex> delete_working_time(working_time)
      {:error, %Ecto.Changeset{}}

  """
  def delete_working_time(%WorkingTime{} = working_time) do
    Repo.delete(working_time)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking working_time changes.

  ## Examples

      iex> change_working_time(working_time)
      %Ecto.Changeset{data: %WorkingTime{}}

  """
  def change_working_time(%WorkingTime{} = working_time, attrs \\ %{}) do
    WorkingTime.changeset(working_time, attrs)
  end

  # ─── Query functions for routes ────────────────────────────────

  def list_for_user(user_id, start_iso \\ nil, end_iso \\ nil) do
    WorkingTime
    |> where([w], w.user_id == ^user_id)
    |> filter_by_start(start_iso)
    |> filter_by_end(end_iso)
    |> order_by([w], desc: w.start_at)
    |> Repo.all()
  end

  def get_for_user!(user_id, id) do
    Repo.get_by!(WorkingTime, id: id, user_id: user_id)
  end

  # ─── Clock logic ───────────────────────────────────────────────

  def clock_in(user_id) do
    if open_session?(user_id) do
      {:error, :already_clocked_in}
    else
      %WorkingTime{}
      |> WorkingTime.changeset(%{user_id: user_id, start_at: now()})
      |> Repo.insert()
    end
  end

  def clock_out(user_id) do
    case open_session(user_id) do
      nil -> {:error, :not_clocked_in}
      wt -> wt |> WorkingTime.changeset(%{end_at: now()}) |> Repo.update()
    end
  end

  def open_session(user_id) do
    Repo.one(
      from(w in WorkingTime,
        where: w.user_id == ^user_id and is_nil(w.end_at),
        order_by: [desc: w.start_at],
        limit: 1
      )
    )
  end

  # ─── Private helpers ───────────────────────────────────────────

  defp open_session?(user_id), do: not is_nil(open_session(user_id))

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)

  defp filter_by_start(q, nil), do: q

  defp filter_by_start(q, iso) do
    case DateTime.from_iso8601(iso) do
      {:ok, dt, _} -> where(q, [w], w.start_at >= ^dt)
      _ -> q
    end
  end

  defp filter_by_end(q, nil), do: q

  defp filter_by_end(q, iso) do
    case DateTime.from_iso8601(iso) do
      {:ok, dt, _} -> where(q, [w], w.start_at <= ^dt)
      _ -> q
    end
  end
end
