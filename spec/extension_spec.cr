require "./spec_helper"

describe AsciicrystalDiagram::DiagramBlockProcessor do
  describe "#initialize" do
    it "sets the tool name" do
      proc = AsciicrystalDiagram::DiagramBlockProcessor.new("plantuml")
      proc.tool_name.should eq("plantuml")
      proc.name.should eq("plantuml")
    end

    it "accepts all supported diagram types" do
      AsciicrystalDiagram::DIAGRAM_NAMES.each do |name|
        proc = AsciicrystalDiagram::DiagramBlockProcessor.new(name)
        proc.tool_name.should eq(name)
      end
    end
  end

  describe "contexts" do
    it "supports listing, literal, open, and paragraph contexts" do
      proc = AsciicrystalDiagram::DiagramBlockProcessor.new("plantuml")
      contexts = proc.contexts
      contexts.should contain(:listing)
      contexts.should contain(:literal)
      contexts.should contain(:open)
      contexts.should contain(:paragraph)
    end
  end
end

describe AsciicrystalDiagram::DiagramExtensionGroup do
  it "can be instantiated" do
    group = AsciicrystalDiagram::DiagramExtensionGroup.new
    group.should be_a(Asciicrystal::Extensions::Group)
  end
end
