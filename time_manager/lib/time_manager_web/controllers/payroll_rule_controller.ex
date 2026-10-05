defmodule TimeManagerWeb.PayrollRuleController do
  use TimeManagerWeb, :controller

  alias TimeManager.PayrollRules

  def index(conn, _params), do: json(conn, %{data: Enum.map(PayrollRules.list_all(), &data/1)})

  def create(conn, params) do
    attrs = Map.put(Map.get(params, "payroll_rule", params), "created_by_id", conn.assigns.current_user.id)
    case PayrollRules.create(attrs) do
      {:ok, rule} -> conn |> put_status(:created) |> json(%{data: data(rule)})
      {:error, changeset} -> validation_error(conn, changeset)
    end
  end

  def update(conn, %{"id" => id} = params) do
    with rule when not is_nil(rule) <- PayrollRules.get(id),
         {:ok, updated} <- PayrollRules.update(rule, Map.get(params, "payroll_rule", params)) do
      json(conn, %{data: data(updated)})
    else
      nil -> send_resp(conn, :not_found, "")
      {:error, changeset} -> validation_error(conn, changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    case PayrollRules.get(id) do
      nil -> send_resp(conn, :not_found, "")
      rule -> PayrollRules.delete(rule) && send_resp(conn, :no_content, "")
    end
  end

  defp data(rule), do: %{id: rule.id, name: rule.name, rule_type: rule.rule_type, value: rule.value, active: rule.active, created_by_id: rule.created_by_id}
  defp validation_error(conn, changeset), do: conn |> put_status(:unprocessable_entity) |> json(%{error: "Invalid data", details: Ecto.Changeset.traverse_errors(changeset, fn {message, _} -> message end)})
end