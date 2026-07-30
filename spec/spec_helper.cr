require "spec"
require "../src/asciicrystal_diagram"

# Unregister global extensions before each test to avoid interference.
Asciicrystal::Extensions.unregister_all

module SpecHelper
  SPEC_OUTPUT_DIR = File.join(__DIR__, "output")

  def self.setup_output_dir : String
    Dir.mkdir_p(SPEC_OUTPUT_DIR) unless Dir.exists?(SPEC_OUTPUT_DIR)
    SPEC_OUTPUT_DIR
  end

  def self.cleanup_output_dir : Nil
    if Dir.exists?(SPEC_OUTPUT_DIR)
      Dir.each_child(SPEC_OUTPUT_DIR) do |entry|
        path = File.join(SPEC_OUTPUT_DIR, entry)
        File.delete(path) if File.file?(path)
      end
    end
  end
end
