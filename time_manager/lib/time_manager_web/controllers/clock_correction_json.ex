defmodule TimeManagerWeb.ClockCorrectionJSON do
  def index(%{clock_corrections: corrections}) do
    %{data: for(correction <- corrections, do: data(correction))}
  end

  def show(%{clock_correction: correction}) do
    %{data: data(correction)}
  end

  defp data(correction) do
    %{
      id: correction.id,
      original_clock_id: correction.original_clock_id,
      user_id: correction.user_id,
      proposed_time: correction.proposed_time,
      proposed_status: correction.proposed_status,
      reason: correction.reason,
      status: correction.status,
      reviewed_by_id: correction.reviewed_by_id,
      reviewed_at: correction.reviewed_at,
      inserted_at: correction.inserted_at,
      updated_at: correction.updated_at
    }
  end
end
