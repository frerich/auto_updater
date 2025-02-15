defmodule AutoUpdater.Secrets.SecretsManager do
  @moduledoc """
  Fetch secrets stored in AWS SecretsManager.
  """
  @behaviour AutoUpdater.Secrets

  @impl AutoUpdater.Secrets
  def get_secrets do
    secret_id = config()[:secret_id]

    request(
      method: :post,
      headers: [{"x-amz-target", "secretsmanager.GetSecretValue"}],
      body: ~s|{"SecretId" : "#{secret_id}"}|
    )
  end

  def request(opts \\ []) when is_list(opts) do
    case Req.request(new(opts)) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  def new(opts \\ []) when is_list(opts) do
    region = config()[:region]

    Req.new(
      aws_sigv4:
        [service: :secretsmanager] ++
          Keyword.take(config(), [:access_key_id, :secret_access_key, :region]),
      retry: :transient,
      url: "https://secretsmanager.#{region}.amazonaws.com",
      headers: [{"content-type", "application/x-amz-json-1.1"}]
    )
    |> Req.merge(opts)
  end

  def config do
    Application.fetch_env!(:auto_updater, __MODULE__)
  end
end
