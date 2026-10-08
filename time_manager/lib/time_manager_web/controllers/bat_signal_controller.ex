defmodule TimeManagerWeb.BatSignalController do
  @moduledoc """
  Contrôleur Bat-Signal : gère le déclenchement d'urgence.
  L'état est stocké en mémoire via :persistent_term (survit aux rechargements de code).
  """
  use TimeManagerWeb, :controller

  # POST /api/bat-signal/trigger — déclencher une alerte d'urgence
  def trigger(conn, %{"message" => message}) do
    :persistent_term.put(:bat_signal_active, true)
    :persistent_term.put(:bat_signal_message, message)
    :persistent_term.put(:bat_signal_triggered_at, DateTime.utc_now() |> DateTime.to_iso8601())

    json(conn, %{data: %{active: true, message: message}})
  end

  def trigger(conn, _params) do
    :persistent_term.put(:bat_signal_active, true)
    :persistent_term.put(:bat_signal_message, "Alerte d'urgence activée – Mobilisation immédiate requise.")
    :persistent_term.put(:bat_signal_triggered_at, DateTime.utc_now() |> DateTime.to_iso8601())

    json(conn, %{data: %{active: true, message: "Alerte d'urgence activée – Mobilisation immédiate requise."}})
  end

  # DELETE /api/bat-signal/trigger — désactiver l'alerte
  def clear(conn, _params) do
    :persistent_term.put(:bat_signal_active, false)
    :persistent_term.put(:bat_signal_message, nil)
    :persistent_term.put(:bat_signal_triggered_at, nil)

    json(conn, %{data: %{active: false}})
  end

  # GET /api/bat-signal/status — lire l'état actuel
  def status(conn, _params) do
    active = :persistent_term.get(:bat_signal_active, false)
    message = :persistent_term.get(:bat_signal_message, nil)
    triggered_at = :persistent_term.get(:bat_signal_triggered_at, nil)

    json(conn, %{data: %{active: active, message: message, triggered_at: triggered_at}})
  end
end
