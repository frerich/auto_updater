defmodule AutoUpdater.ReleaseWatcher do
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(nil) do
    polling_interval_ms =
      Application.get_env(:auto_updater, :polling_interval_ms, :timer.seconds(5))

    current_version =
      with {:ok, version} <- AutoUpdater.Installation.current_version() do
        version
      end

    Logger.info("Polling for new releases every #{polling_interval_ms}ms.")

    Process.send_after(self(), :check_version, polling_interval_ms)
    {:ok, [current_version: current_version, polling_interval_ms: polling_interval_ms]}
  end

  def handle_info(:check_version, state) do
    current_version = state[:current_version]
    Logger.debug("Polling for new release version.")

    case AutoUpdater.Storage.desired_version() do
      {:ok, ^current_version} ->
        Logger.debug("Current version is still desired version.")

      {:ok, desired_version} ->
        Logger.debug("Found new version #{desired_version}.")
        AutoUpdater.Deploy.deploy(desired_version)

      {:error, _what} ->
        Logger.warning("Failed to identify desired release version.")
    end

    Process.send_after(self(), :check_version, state[:polling_interval_ms])
    {:noreply, state}
  end
end
