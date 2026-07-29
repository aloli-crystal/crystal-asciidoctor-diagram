require "./spec_helper"

describe AsciicrystalDiagram::Generator do
  describe "TOOL_SPECS" do
    it "contains entries for all supported diagram types" do
      expected = %w[plantuml mermaid ditaa graphviz dot blockdiag seqdiag actdiag nwdiag umlet svgbob pikchr d2 lilypond gnuplot]
      expected.each do |name|
        AsciicrystalDiagram::TOOL_SPECS.has_key?(name).should be_true
      end
    end

    it "each spec has a non-empty default_cmd" do
      AsciicrystalDiagram::TOOL_SPECS.each do |name, spec|
        spec.default_cmd.empty?.should be_false
      end
    end

    it "each spec has a non-empty input_ext" do
      AsciicrystalDiagram::TOOL_SPECS.each do |name, spec|
        spec.input_ext.starts_with?(".").should be_true
      end
    end

    it "each spec has a non-empty path_attr" do
      AsciicrystalDiagram::TOOL_SPECS.each do |name, spec|
        spec.path_attr.empty?.should be_false
      end
    end
  end

  describe "DIAGRAM_NAMES" do
    it "lists all supported diagram names" do
      AsciicrystalDiagram::DIAGRAM_NAMES.size.should eq(AsciicrystalDiagram::TOOL_SPECS.size)
    end
  end

  describe ".generate" do
    it "raises ToolError for unknown tool" do
      expect_raises(AsciicrystalDiagram::Generator::ToolError, /Unknown diagram tool/) do
        AsciicrystalDiagram::Generator.generate("nonexistent_tool", "source")
      end
    end

    it "uses cache when available" do
      cache_dir = File.join(SpecHelper::SPEC_OUTPUT_DIR, "gen_cache_test")
      Dir.mkdir_p(cache_dir) unless Dir.exists?(cache_dir)
      cache = AsciicrystalDiagram::Cache.new(cache_dir)

      # Pre-populate cache
      source = "cached diagram"
      cached_data = "<svg>cached</svg>"
      cache.put(source, "svg", cached_data)

      # Should return cached data without calling external tool
      result = AsciicrystalDiagram::Generator.generate("plantuml", source, "svg", cache: cache)
      result.should eq(cached_data)

      # Cleanup
      cache.clear!
    end
  end
end
