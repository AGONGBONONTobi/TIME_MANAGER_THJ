defmodule TimeManager.Clocking do
  @moduledoc """
  Contexte métier pour la gestion des pointages (clocks).
  """

  import Ecto.Query
  alias TimeManager.Repo
  alias TimeManager.Clocking.Clock
  alias TimeManager.Accounts.User

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

  @doc """
  Récupère le dernier clock d'un utilisateur.
  Retourne `nil` s'il n'y en a aucun.
  """
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
    user = Repo.get!(User, user_id)

    status = user_id |> get_last_clock() |> determine_status()

    user
    |> Ecto.build_assoc(:clocks, %{
      time: DateTime.utc_now() |> DateTime.truncate(:second),
      status: status
    })
    |> Repo.insert()
  end

  defp determine_status(nil), do: true
  defp determine_status(%Clock{status: true}), do: false
  defp determine_status(%Clock{status: false}), do: true
end
