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

  def get_for_user!(user_id, id), do: Repo.get_by!(WorkingTime, id: id, user_id: user_id)

  def get_for_user(user_id, id), do: Repo.get_by(WorkingTime, id: id, user_id: user_id)

  def list_for_user(user_id, start_date \\ nil, end_date \\ nil) do
    WorkingTime
    |> where([w], w.user_id == ^user_id)
    |> filter_by_start(start_date)
    |> filter_by_end(end_date)
    |> order_by([w], desc: w.start)
    |> Repo.all()
  end

  def create_for_user(user_id, attrs) do
    case Repo.get(TimeManager.Accounts.User, user_id) do
      nil -> {:error, :user_not_found}
      _user -> create_working_time(Map.put(attrs, "user_id", user_id))
    end
  end

  def start_session(user_id) do
    case Repo.get(TimeManager.Accounts.User, user_id) do
      nil ->
        {:error, :user_not_found}

      _user ->
        if open_session(user_id) do
          {:error, :already_clocked_in}
        else
          create_working_time(%{
            "user_id" => user_id,
            "start" => DateTime.utc_now() |> DateTime.truncate(:second)
          })
        end
    end
  end

  def open_session(user_id) do
    Repo.one(
      from w in WorkingTime,
        where: w.user_id == ^user_id and is_nil(w.end),
        order_by: [desc: w.start],
        limit: 1
    )
  end

  defp filter_by_start(query, nil), do: query
  defp filter_by_start(query, value), do: filter_datetime(query, :start, value, :>=)

  defp filter_by_end(query, nil), do: query
  defp filter_by_end(query, value), do: filter_datetime(query, :start, value, :<=)

  defp filter_datetime(query, field, value, operator) do
    case DateTime.from_iso8601(String.replace(value, " ", "T")) do
      {:ok, datetime, _offset} when operator == :>= ->
        where(query, [w], field(w, ^field) >= ^datetime)

      {:ok, datetime, _offset} when operator == :<= ->
        where(query, [w], field(w, ^field) <= ^datetime)

      _ ->
        query
    end
  end

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
