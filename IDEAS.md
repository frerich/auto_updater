* Don't store version in 'version.txt' file but use version as available in
  `Application.spec(:app)[:vsn]`; requires maintaining that version in mix.exs
  but avoids having to write out a file.
* Optionally verify digital signatures of downloaded releases.
* Permit specifying callback to be invoked before restarting (e.g. for draining connections).
* Strategies for doing rolling/incremental updates of multiple instances (Postgres advisory locks? Random sleep before restart?)
* Consider unpacking & validating releases using [:release_handler.unpack_release/1](https://www.erlang.org/docs/26/man/release_handler#unpack_release-1).
* Make dependency on Jason & Req optional.
* Allow manually checking for and deploying new releases instead of doing so automatically.
