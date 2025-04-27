defmodule AutoUpdater.Storage.S3 do
  @moduledoc """
  Models a AWS S3 bucket as a release repository.
  """
  @behaviour AutoUpdater.Storage

  alias AutoUpdater.Temp

  @impl AutoUpdater.Storage
  def desired_version do
    with {:ok, body} <- request(url: config()[:release_version_file]) do
      {:ok, String.trim(body)}
    end
  end

  @impl AutoUpdater.Storage
  def download_release(version) when is_binary(version) do
    local_path = Temp.path!(prefix: Path.basename(version))

    with {:ok, _} <- request(url: version, into: File.stream!(local_path)) do
      {:ok, local_path}
    end
  end

  def new(opts \\ []) when is_list(opts) do
    Req.new(
      aws_sigv4:
        [service: :s3] ++ Keyword.take(config(), [:access_key_id, :secret_access_key, :region]),
      base_url: config()[:endpoint],
      retry: :transient
    )
    |> Req.merge(opts)
    |> Req.merge(Application.get_env(:auto_updater, :req_test_options, []))
  end

  def request(opts \\ []) when is_list(opts) do
    case Req.request(new(opts)) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  def config do
    defaults = [region: "eu-central-1"]
    Keyword.merge(defaults, Application.fetch_env!(:auto_updater, :storage_config))
  end
end
