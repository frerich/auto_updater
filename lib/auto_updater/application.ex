defmodule AutoUpdater.Application do
  use Application

  require Logger

  def start(_, _) do
    opts = [strategy: :one_for_one, name: AutoUpdater.Supervisor]

    children = [
      AutoUpdater.ReleaseWatcher
    ]

    children =
      if Application.get_env(:auto_updater, :secrets) do
        children ++ [AutoUpdater.SecretsWatcher]
      else
        Logger.info("secrets not configured for auto_updater, disabling polling for new secrets")
        children
      end

    Supervisor.start_link(children, opts)
  end
end
