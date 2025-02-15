defmodule AutoUpdater.SecretsWatcher do
  @moduledoc """
  Periodically check for changed secrets and reload OTP applications if necessary.
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

        Logger.info("Polling for new secrets every #{polling_interval_ms}ms.")

        Process.send_after(self(), :poll, polling_interval_ms)
        {:ok, [polling_interval_ms: polling_interval_ms]}

      {:error, reason} when is_binary(reason) ->
        Logger.info("Disabling monitor of secrets: #{reason}")
        :ignore
    end
  end

  def handle_info(:poll, state) do
    Logger.debug("Polling for new secrets.")

    case AutoUpdater.Secrets.get_secrets() do
      {:ok, desired_secrets} ->
        current_secrets = Map.take(System.get_env(), Map.keys(desired_secrets))

        if desired_secrets != current_secrets do
          Logger.debug("Secrets changed, restarting.")
          System.restart()
        else
          Logger.debug("Secrets unchanged.")
          Process.send_after(self(), :poll, state[:polling_interval_ms])
        end

      {:error, what} ->
        Logger.warning("Failed to fetch current secrets: #{inspect(what)}")
        Process.send_after(self(), :poll, state[:polling_interval_ms])
    end

    {:noreply, state}
  end

  def validate_configuration do
    case Application.get_env(:auto_updater, :secrets) do
      nil -> {:error, ":secrets not set"}
      _ -> :ok
    end
  end
end
