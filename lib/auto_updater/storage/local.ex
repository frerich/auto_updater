defmodule AutoUpdater.Storage.Local do
  @behaviour AutoUpdater.Storage

  @impl AutoUpdater.Storage
  def desired_version() do
    release_version_path = Path.join(config()[:prefix_dir], config()[:release_version_file])

    with {:ok, body} <- File.read(release_version_path) do
      {:ok, String.trim(body)}
    end
  end

  @impl AutoUpdater.Storage
  def download_release(version) do
    local_path = temp_path!(Path.basename(version))
    release_path = Path.join(config()[:prefix_dir], version)

    with :ok <- File.cp(release_path, local_path) do
      {:ok, local_path}
    end
  end

  def config do
    Application.fetch_env!(:auto_updater, __MODULE__)
  end

  def temp_path!(suffix) when is_binary(suffix) do
    Path.join(System.tmp_dir!(), "#{Enum.random(0..(2 ** 64))}-#{suffix}")
  end
end
