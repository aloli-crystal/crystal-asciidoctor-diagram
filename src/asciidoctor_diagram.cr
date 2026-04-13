require "crystal-asciidoctor"
require "./asciidoctor_diagram/cache"
require "./asciidoctor_diagram/generator"
require "./asciidoctor_diagram/extension"

module AsciidoctorDiagram
  VERSION = "3.2.1"

  # Version of the upstream Ruby gem used as reference.
  UPSTREAM_VERSION = "3.2.1"
end
