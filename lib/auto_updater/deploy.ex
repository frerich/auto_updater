defmodule AutoUpdater.Deploy do
  @moduledoc """
  Functionality for deploying a new version.
  """
  require Logger

  alias AutoUpdater.Temp

  def deploy(desired_version) do
    Logger.debug("Starting to deploy version #{desired_version}.")

    with {:ok, release_pkg_path} <- AutoUpdater.Storage.download_release(desired_version),
         {:ok, tmp_install_dir} <- unpack(release_pkg_path),
         :ok <- sanity_check(tmp_install_dir),
         :ok <- upgrade_installation(release_pkg_path),
         :ok <- AutoUpdater.Installation.set_current_version(desired_version),
         :ok <- cleanup(release_pkg_path, tmp_install_dir) do
      restart()
    end
  end

  def unpack(pkg_path) when is_binary(pkg_path) do
    temp_dir = Temp.path!(prefix: "autoupdater")
    Logger.debug("Unpacking #{pkg_path} to #{temp_dir}")

    with :ok <- File.mkdir(temp_dir),
         :ok <- unpack_to(pkg_path, temp_dir) do
      {:ok, temp_dir}
    end
  end

  def sanity_check(tmp_install_dir) when is_binary(tmp_install_dir) do
    app_name = Application.fetch_env!(:auto_updater, :otp_app)
    executable = Path.join([tmp_install_dir, "bin", to_string(app_name)])

    Logger.debug("Performing sanity check by running #{executable}")

    case System.cmd(executable, ["eval", "IO.puts(\"OK\")"]) do
      {"OK\n", 0} -> :ok
      result -> {:error, {:sanity_check_failed, result}}
    end
  end

  def upgrade_installation(pkg_path) when is_binary(pkg_path) do
    Logger.debug(
      "Unpacking #{pkg_path} to installation directory #{AutoUpdater.Installation.install_dir()}"
    )

    unpack_to(pkg_path, AutoUpdater.Installation.install_dir())
  end

  def cleanup(release_pkg_path, tmp_install_dir)
      when is_binary(release_pkg_path) and is_binary(tmp_install_dir) do
    Logger.debug("Removing downloaded release package #{release_pkg_path}")

    with {:error, _reason} <- File.rm(release_pkg_path) do
      Logger.warning("Failed to remove release package #{release_pkg_path}.")
    end

    Logger.debug("Removing temporary directory #{tmp_install_dir}")

    with {:error, _reason, _file} <- File.rm_rf(tmp_install_dir) do
      Logger.warning("Failed to remove temporary installation directory #{tmp_install_dir}")
    end

    :ok
  end

  def restart do
    app_name = Application.fetch_env!(:auto_updater, :otp_app)
    script = Path.join([AutoUpdater.Installation.install_dir(), "bin", to_string(app_name)])

    case System.cmd(script, ["restart"]) do
      {_output, 0} -> :ok
      result -> {:error, {:restart_failed, result}}
    end
  end

  def unpack_to(pkg_path, dest_dir) do
    case System.cmd("tar", ["-C", dest_dir, "-zxf", pkg_path]) do
      {_output, 0} -> :ok
      result -> {:error, {:unpack_failed, result}}
    end
  end
end
