defmodule AutoUpdater.Storage.S3Test do
  use ExUnit.Case, async: true

  alias AutoUpdater.Storage.S3
  alias Plug.Conn

  setup do
    Application.put_env(:auto_updater, :storage_config,
      endpoint: "https://test-bucket.s3.test-region.amazonaws.com",
      access_key_id: "test_key",
      secret_access_key: "test_secret",
      region: "test-region",
      release_version_file: "version.txt"
    )

    Application.put_env(:auto_updater, :req_test_options,
      plug: {Req.Test, AutoUpdater.Storage.S3}
    )

    Req.Test.verify_on_exit!()

    :ok
  end

  describe "desired_version/0" do
    test "returns content of version file when available" do
      Req.Test.expect(AutoUpdater.Storage.S3, fn conn ->
        assert conn.method == "GET"

        assert Conn.request_url(conn) ==
                 "https://test-bucket.s3.test-region.amazonaws.com/version.txt"

        assert_aws_auth_header(conn)
        Req.Test.text(conn, "1.2.3\n")
      end)

      assert {:ok, "1.2.3"} = S3.desired_version()
    end

    test "handles missing version file" do
      Req.Test.expect(AutoUpdater.Storage.S3, fn conn ->
        assert conn.method == "GET"

        assert Conn.request_url(conn) ==
                 "https://test-bucket.s3.test-region.amazonaws.com/version.txt"

        assert_aws_auth_header(conn)
        conn |> Conn.put_status(404) |> Req.Test.text("Not found")
      end)

      assert {:error, %{status: 404}} = S3.desired_version()
    end

    test "handles network errors and retries" do
      # Expect four calls: one initial attempt and three retries.
      Req.Test.expect(AutoUpdater.Storage.S3, 4, fn conn ->
        Req.Test.transport_error(conn, :econnrefused)
      end)

      assert {:error, %Req.TransportError{reason: :econnrefused}} = S3.desired_version()
    end
  end

  describe "download_release/1" do
    test "downloads release file to temp location" do
      Req.Test.expect(AutoUpdater.Storage.S3, fn conn ->
        assert conn.method == "GET"

        assert Conn.request_url(conn) ==
                 "https://test-bucket.s3.test-region.amazonaws.com/1.2.3.tar.gz"

        assert_aws_auth_header(conn)

        conn
        |> Conn.put_resp_header("content-type", "application/gzip")
        |> Conn.send_resp(200, "release content")
      end)

      assert {:ok, temp_path} = S3.download_release("1.2.3.tar.gz")
      assert File.read!(temp_path) == "release content"
    end

    test "handles missing release file" do
      Req.Test.expect(AutoUpdater.Storage.S3, fn conn ->
        assert conn.method == "GET"

        assert Conn.request_url(conn) ==
                 "https://test-bucket.s3.test-region.amazonaws.com/1.2.3.tar.gz"

        assert_aws_auth_header(conn)
        conn |> Conn.put_status(404) |> Req.Test.text("Not found")
      end)

      assert {:error, %{status: 404}} = S3.download_release("1.2.3.tar.gz")
    end

    test "handles network errors" do
      # Expect four calls: one initial attempt and three retries.
      Req.Test.expect(AutoUpdater.Storage.S3, 4, fn conn ->
        Req.Test.transport_error(conn, :econnrefused)
      end)

      assert {:error, %Req.TransportError{reason: :econnrefused}} =
               S3.download_release("1.2.3.tar.gz")
    end
  end

  defp assert_aws_auth_header(conn) do
    case Conn.get_req_header(conn, "authorization") do
      [value] -> assert String.starts_with?(value, "AWS4-HMAC-SHA256")
      [] -> assert false
    end
  end
end
