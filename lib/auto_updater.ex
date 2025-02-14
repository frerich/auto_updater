defmodule AutoUpdater do
  require Logger

  def load_secrets() do
    case AutoUpdater.Secrets.get_secrets() do
      {:ok, secrets} ->
        System.put_env(secrets)
      {:error, reason} ->
        Logger.warning("Failed to load secrets: #{reason}")
        {:error, reason}
    end
  end
end
