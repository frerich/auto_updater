defmodule AutoUpdater.Installation do
  @moduledoc """
  Provides access to the currently installed application.
  """
  def current_version do
    case File.read(Path.join(install_dir(), "version.txt")) do
      {:ok, content} -> {:ok, String.trim(content)}
      {:error, _} -> nil
    end
  end

  def set_current_version(version) when is_binary(version) do
    File.write(Path.join(install_dir(), "version.txt"), version)
  end

  def install_dir do
    app_dir = Application.app_dir(config(:otp_app))
    Path.expand("../..", app_dir)
  end

  def config(key) when is_atom(key) do
    Application.fetch_env!(:auto_updater, key)
  end
end
