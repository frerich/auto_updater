defmodule AutoUpdater.Application do
  @moduledoc """
  Supervisor for AutoUpdater processes.
  """
  use Application

  def start(_, _) do
    opts = [strategy: :one_for_one, name: AutoUpdater.Supervisor]

    children = [
      AutoUpdater.ReleaseWatcher,
      AutoUpdater.SecretsWatcher
    ]

    Supervisor.start_link(children, opts)
  end
end
