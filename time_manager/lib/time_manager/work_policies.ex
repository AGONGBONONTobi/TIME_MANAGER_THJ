defmodule TimeManager.WorkPolicies do
  import Ecto.Query, warn: false
  alias TimeManager.Repo
  alias TimeManager.WorkPolicies.{UserWorkPolicy, WorkPolicy}

  def list_active, do: Repo.all(from p in WorkPolicy, where: p.active, order_by: p.name)
  def list_all, do: Repo.all(from p in WorkPolicy, order_by: p.name)
  def get(id), do: Repo.get(WorkPolicy, id)
  def create(attrs), do: %WorkPolicy{} |> WorkPolicy.changeset(attrs) |> Repo.insert()
  def update(%WorkPolicy{} = policy, attrs), do: policy |> WorkPolicy.changeset(attrs) |> Repo.update()
  def delete(%WorkPolicy{} = policy), do: Repo.delete(policy)

  def assign(user_id, policy_id, starts_on) do
    %UserWorkPolicy{}
    |> UserWorkPolicy.changeset(%{user_id: user_id, policy_id: policy_id, starts_on: starts_on})
    |> Repo.insert()
  end

  def get_for_user(user_id, date \\ Date.utc_today()) do
    Repo.one(
      from a in UserWorkPolicy,
        where: a.user_id == ^user_id and a.starts_on <= ^date and (is_nil(a.ends_on) or a.ends_on >= ^date),
        order_by: [desc: a.starts_on],
        limit: 1,
        preload: [:policy]
    )
  end
end