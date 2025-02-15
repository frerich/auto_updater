defmodule AutoUpdater.ReleaseWatcher do
  @moduledoc """
  Periodically checks for new releases and triggers a deployment.
  """
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(nil) do
    case validate_configuration() do
      :ok ->
        polling_interval_ms =
          Application.get_env(:auto_updater, :polling_interval_ms, :timer.seconds(5))

        current_version =
          with {:ok, version} <- AutoUpdater.Installation.current_version() do
            version
          end

        Logger.info("Polling for new releases every #{polling_interval_ms}ms.")

        Process.send_after(self(), :check_version, polling_interval_ms)
        {:ok, [current_version: current_version, polling_interval_ms: polling_interval_ms]}

      {:error, reason} when is_binary(reason) ->
        Logger.info("Disabling automatic updates: #{reason}")
        :ignore
    end
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

      {:error, what} ->
        Logger.warning("Failed to identify desired release version: #{inspect(what)}")
    end

    Process.send_after(self(), :check_version, state[:polling_interval_ms])
    {:noreply, state}
  end

  def validate_configuration do
    with :ok <- validate_otp_app_config() do
      validate_storage_config()
    end
  end

  def validate_otp_app_config do
    case Application.get_env(:auto_updater, :otp_app) do
      nil -> {:error, ":otp_app not set"}
      _ -> :ok
    end
  end

  def validate_storage_config do
    case Application.get_env(:auto_updater, :storage) do
      nil -> {:error, ":storage not set"}
      _ -> :ok
    end
  end
end
