defmodule TimeManager.PayrollRules.PayrollRule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "payroll_rules" do
    field :name, :string
    field :rule_type, :string
    field :value, :decimal
    field :active, :boolean, default: true
    belongs_to :created_by, TimeManager.Accounts.User
    timestamps(type: :utc_datetime)
  end

  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [:name, :rule_type, :value, :active, :created_by_id])
    |> validate_required([:name, :rule_type, :value])
    |> validate_number(:value, greater_than_or_equal_to: 0)
    |> unique_constraint(:name)
  end
end