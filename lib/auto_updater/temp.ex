defmodule AutoUpdater.Temp do
  @moduledoc """
  Dealing with temporary file system paths.
  """

  def path!(opts \\ []) do
    opts = Keyword.validate!(opts, :prefix)

    path =
      case opts[:prefix] do
        nil -> "#{Enum.random(0..(2 ** 64))}"
        prefix -> "#{prefix}-#{Enum.random(0..(2 ** 64))}"
      end

    Path.join(System.tmp_dir!(), path)
  end
end
