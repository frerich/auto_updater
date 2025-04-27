defmodule AutoUpdater.Storage.LocalTest do
  use ExUnit.Case

  alias AutoUpdater.Storage.Local

  setup %{tmp_dir: tmp_dir} do
    Application.put_env(:auto_updater, :storage_config,
      prefix_dir: tmp_dir,
      release_version_file: "version.txt"
    )

    :ok
  end

  describe "desired_version/0" do
    @tag :tmp_dir
    test "returns content of version file when available", %{tmp_dir: tmp_dir} do
      version_path = Path.join(tmp_dir, "version.txt")
      File.write!(version_path, "1.2.3\n")

      assert {:ok, "1.2.3"} = Local.desired_version()
    end

    @tag :tmp_dir
    test "handles missing version file", %{tmp_dir: tmp_dir} do
      version_path = Path.join(tmp_dir, "version.txt")
      File.rm_rf!(version_path)

      assert {:error, :enoent} = Local.desired_version()
    end

    @tag :tmp_dir
    test "handles unreadable version file", %{tmp_dir: tmp_dir} do
      version_path = Path.join(tmp_dir, "version.txt")
      File.write!(version_path, "1.2.3")
      File.chmod!(version_path, 0o000)

      assert {:error, :eacces} = Local.desired_version()
    after
      # Restore permissions for cleanup
      Path.join(tmp_dir, "version.txt")
      |> File.chmod!(0o644)
    end
  end

  describe "download_release/1" do
    @tag :tmp_dir
    test "copies release file to temp location", %{tmp_dir: tmp_dir} do
      release_path = Path.join(tmp_dir, "1.2.3.tar.gz")
      File.write!(release_path, "release content")

      assert {:ok, temp_path} = Local.download_release("1.2.3.tar.gz")
      assert File.read!(temp_path) == "release content"
    end

    @tag :tmp_dir
    test "handles missing release file", %{tmp_dir: tmp_dir} do
      release_path = Path.join(tmp_dir, "1.2.3.tar.gz")
      File.rm_rf!(release_path)

      assert {:error, :enoent} = Local.download_release("1.2.3.tar.gz")
    end

    @tag :tmp_dir
    test "handles unreadable release file", %{tmp_dir: tmp_dir} do
      release_path = Path.join(tmp_dir, "1.2.3.tar.gz")
      File.write!(release_path, "release content")
      File.chmod!(release_path, 0o000)

      assert {:error, :eacces} = Local.download_release("1.2.3.tar.gz")
    after
      # Restore permissions for cleanup
      Path.join(tmp_dir, "1.2.3.tar.gz")
      |> File.chmod!(0o644)
    end
  end
end
