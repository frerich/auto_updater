defmodule AutoUpdater.Storage do
  @moduledoc """
  Abstracts a repository containing release tarballs.
  """
  @callback desired_version() :: {:ok, String.t()} | {:error, any()}
  @callback download_release(version :: String.t()) :: {:ok, Path.t()} | {:error, any()}

  def desired_version, do: impl().desired_version()

  def download_release(version) when is_binary(version) do
    impl().download_release(version)
  end

  def impl, do: Application.fetch_env!(:auto_updater, :storage)
end
