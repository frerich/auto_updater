defmodule AutoUpdater.Secrets.EncryptedJsonFile do
  @moduledoc """
  Fetch secrets from a AES-256 encrypted JSON file.
  """
  @behaviour AutoUpdater.Secrets

  # To encrypt: 'openssl enc -aes-256-cbc -A -a -in /tmp/secrets.json -K '4040404040404040404040404040404040404040404040404040404040404040' -iv '40404040404040404040404040404040' -out /tmp/secrets.json.enc'
  @impl AutoUpdater.Secrets
  def get_secrets do
    with {:ok, encrypted_data} <- fetch(),
         {:ok, decrypted_data} <- decrypt(encrypted_data) do
      :json.decode(decrypted_data)
    end
  end

  def decrypt(data) when is_binary(data) do
    cipher = config()[:cipher]
    key = :binary.decode_hex(config()[:key])
    iv = :binary.decode_hex(config()[:iv])
    decoded_data = :base64.decode(data)
    decrypted_padded_data = :crypto.crypto_one_time(cipher, key, iv, decoded_data, false)

    decrypted_data =
      String.trim_trailing(decrypted_padded_data, String.last(decrypted_padded_data))

    {:ok, decrypted_data}
  end

  def fetch do
    auth_header =
      if auth = config()[:authorization] do
        [{"authorization", auth}]
      else
        []
      end

    case Req.get(url: config()[:url], headers: auth_header, retry: :transient) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  def config do
    :auto_updater
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.validate!([:url, :authorization, :cipher, :iv, :key])
  end
end
