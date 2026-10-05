defmodule TimeManager.Token do
  use Joken.Config

  @impl Joken.Config
  def token_config do
    default_claims(default_exp: 24 * 60 * 60) # 24 hours
  end
end
