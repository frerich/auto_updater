defmodule AutoUpdater.Storage.GitHub do
  @moduledoc """
  Models releases of a GitHub project as a release repository.
  """
  @behaviour AutoUpdater.Storage

  alias AutoUpdater.Temp

  @impl AutoUpdater.Storage
  def desired_version do
    with {:ok, body} <- request(url: "/releases/latest") do
      {:ok, to_string(body["id"])}
    end
  end

  @impl AutoUpdater.Storage
  def download_release(version) when is_binary(version) do
    with {:ok, body} <- request(url: "/releases/#{version}/assets") do
      case body do
        [] ->
          {:error, :no_assets}

        [first_asset | _] ->
          download_asset(first_asset["browser_download_url"])
      end
    end
  end

  def download_asset(url) when is_binary(url) do
    url = URI.parse(url)

    local_path = Temp.path!(prefix: Path.basename(url.path))

    with {:ok, _body} <- request(url: url, into: File.stream!(local_path)) do
      {:ok, local_path}
    end
  end

  def new(opts \\ []) when is_list(opts) do
    auth_header =
      if token = config()[:token] do
        [{"authorization", "Bearer #{token}"}]
      else
        []
      end

    Req.new(
      base_url: "https://api.github.com/repos/#{config()[:owner]}/#{config()[:repo]}",
      headers:
        auth_header ++
          [{"accept", "application/vnd.github+json"}, {"x-github-api-version", "2022-11-28"}],
      retry: :transient
    )
    |> Req.merge(opts)
  end

  def request(opts \\ []) when is_list(opts) do
    case Req.request(new(opts)) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  def config do
    Application.fetch_env!(:auto_updater, :storage_config)
  end
end
