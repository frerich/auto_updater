defmodule AutoUpdater.Application do
  use Application

  def start(_, _) do
    opts = [strategy: :one_for_one, name: AutoUpdater.Supervisor]

    children = [
      AutoUpdater.ReleaseWatcher
    ]

    Supervisor.start_link(children, opts)
  end
end
