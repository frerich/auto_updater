* Don't store version in 'version.txt' file but use version as available in
  `Application.spec(:app)[:vsn]`; requires maintaining that version in mix.exs
  but avoids having to write out a file.
