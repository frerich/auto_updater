defmodule AutoUpdater.Secrets do
  @moduledoc """
  Abstracts fetching the current set of secrets.
  """
  @callback get_secrets() :: {:ok, %{binary() => binary()}} | {:error, any()}

  def get_secrets, do: impl().get_secrets()

  def impl, do: Application.fetch_env!(:auto_updater, :secrets)
end
