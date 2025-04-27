defmodule AutoUpdater.Storage.GitHubTest do
  use ExUnit.Case

  alias AutoUpdater.Storage.GitHub
  alias Plug.Conn

  setup do
    Application.put_env(:auto_updater, :storage_config,
      owner: "john.doe",
      repo: "acmeproject"
    )

    Application.put_env(:auto_updater, :req_test_options,
      plug: {Req.Test, AutoUpdater.Storage.GitHub}
    )

    Req.Test.verify_on_exit!()

    :ok
  end

  describe "desired_version/0" do
    test "returns latest release ID when available" do
      Req.Test.expect(AutoUpdater.Storage.GitHub, fn conn ->
        assert conn.method == "GET"

        assert Conn.request_url(conn) ==
                 "https://api.github.com/repos/john.doe/acmeproject/releases/latest"

        Req.Test.json(conn, %{"id" => "12345"})
      end)

      assert {:ok, "12345"} = GitHub.desired_version()
    end

    test "handles API errors" do
      Req.Test.expect(AutoUpdater.Storage.GitHub, fn conn ->
        assert conn.method == "GET"

        assert Conn.request_url(conn) ==
                 "https://api.github.com/repos/john.doe/acmeproject/releases/latest"

        conn |> Conn.put_status(404) |> Req.Test.text("Not found")
      end)

      assert {:error, %{status: 404}} = GitHub.desired_version()
    end

    test "handles network errors" do
      # Expect four calls: one initial attempt and three retries.
      Req.Test.expect(AutoUpdater.Storage.GitHub, 4, fn conn ->
        Req.Test.transport_error(conn, :econnrefused)
      end)

      assert {:error, %Req.TransportError{reason: :econnrefused}} = GitHub.desired_version()
    end
  end

  describe "download_release/1" do
    test "downloads first asset of a release" do
      Req.Test.expect(AutoUpdater.Storage.GitHub, fn conn ->
        assert conn.method == "GET"

        assert Conn.request_url(conn) ==
                 "https://api.github.com/repos/john.doe/acmeproject/releases/12345/assets"

        Req.Test.json(conn, [
          %{
            "browser_download_url" =>
              "https://api.github.com/repos/john.doe/acmeproject/releases/12345/asset.zip"
          }
        ])
      end)

      Req.Test.expect(AutoUpdater.Storage.GitHub, fn conn ->
        assert conn.method == "GET"

        assert Conn.request_url(conn) ==
                 "https://api.github.com/repos/john.doe/acmeproject/releases/12345/asset.zip"

        Req.Test.text(conn, "fake zip content")
      end)

      assert {:ok, path} = GitHub.download_release("12345")
      assert File.read!(path) == "fake zip content"
    end

    test "handles release with no assets" do
      Req.Test.expect(AutoUpdater.Storage.GitHub, fn conn ->
        assert conn.method == "GET"

        assert Conn.request_url(conn) ==
                 "https://api.github.com/repos/john.doe/acmeproject/releases/12345/assets"

        Req.Test.json(conn, [])
      end)

      assert {:error, :no_assets} = GitHub.download_release("12345")
    end

    test "handles API errors" do
      Req.Test.expect(AutoUpdater.Storage.GitHub, fn conn ->
        assert conn.method == "GET"

        assert Conn.request_url(conn) ==
                 "https://api.github.com/repos/john.doe/acmeproject/releases/99999/assets"

        conn |> Conn.put_status(404) |> Req.Test.text("Not found")
      end)

      assert {:error, %{status: 404}} = GitHub.download_release("99999")
    end
  end

  describe "authentication" do
    test "adds auth header when token is configured" do
      Application.put_env(:auto_updater, :storage_config,
        owner: "john.doe",
        repo: "private_project",
        token: "test_token"
      )

      Req.Test.expect(AutoUpdater.Storage.GitHub, fn conn ->
        assert {"authorization", "Bearer test_token"} in conn.req_headers

        assert Conn.request_url(conn) ==
                 "https://api.github.com/repos/john.doe/private_project/releases/latest"

        Req.Test.json(conn, %{"id" => "12345"})
      end)

      assert {:ok, "12345"} = GitHub.desired_version()
    end
  end
end
