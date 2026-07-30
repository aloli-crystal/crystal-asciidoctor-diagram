require "asciicrystal"
require "./asciicrystal_diagram/cache"
require "./asciicrystal_diagram/generator"
require "./asciicrystal_diagram/extension"

module AsciicrystalDiagram
  # Lue au compile-time depuis `shard.yml` via le macro `read_file`.
  # Cf. note mémoire `feedback_shard_version_macro.md` (mémoire ALOLI).
  VERSION = {{
              (read_file("#{__DIR__}/../shard.yml")
                .lines
                .find(&.starts_with?("version:")) || "version: 0.0.0")
                .gsub(/^version:\s*/, "")
                .chomp
            }}

  # Version of the upstream Ruby gem used as reference.
  UPSTREAM_VERSION = "3.2.1"
end
