defmodule AutoUpdater.Storage.Local do
  @moduledoc """
  Expose a local directory as a release repository.
  """
  @behaviour AutoUpdater.Storage

  alias AutoUpdater.Temp

  @impl AutoUpdater.Storage
  def desired_version do
    release_version_path = Path.join(config()[:prefix_dir], config()[:release_version_file])

    with {:ok, body} <- File.read(release_version_path) do
      {:ok, String.trim(body)}
    end
  end

  @impl AutoUpdater.Storage
  def download_release(version) do
    local_path = Temp.path!(prefix: Path.basename(version))
    release_path = Path.join(config()[:prefix_dir], version)

    with :ok <- File.cp(release_path, local_path) do
      {:ok, local_path}
    end
  end

  def config do
    Application.fetch_env!(:auto_updater, :storage_config)
  end
end
