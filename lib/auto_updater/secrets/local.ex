defmodule AutoUpdater.Secrets.Local do
  @behaviour AutoUpdater.Secrets

  require Logger

  @impl AutoUpdater.Secrets
  def get_secrets() do
    Logger.debug("Reading current secrets from #{config()[:path]}")

    with {:ok, json} <- File.read(config()[:path]) do
      Jason.decode(json)
    end
  end

  def config() do
    Application.fetch_env!(:auto_updater, __MODULE__)
  end
end
