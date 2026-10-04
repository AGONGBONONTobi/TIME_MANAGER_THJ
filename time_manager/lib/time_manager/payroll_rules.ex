defmodule TimeManager.PayrollRules do
  import Ecto.Query, warn: false
  alias TimeManager.Repo
  alias TimeManager.PayrollRules.PayrollRule

  def list_active, do: Repo.all(from r in PayrollRule, where: r.active, order_by: r.name)
  def list_all, do: Repo.all(from r in PayrollRule, order_by: r.name)
  def get(id), do: Repo.get(PayrollRule, id)
  def create(attrs), do: %PayrollRule{} |> PayrollRule.changeset(attrs) |> Repo.insert()
  def update(%PayrollRule{} = rule, attrs), do: rule |> PayrollRule.changeset(attrs) |> Repo.update()
  def delete(%PayrollRule{} = rule), do: Repo.delete(rule)
end