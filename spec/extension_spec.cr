require "./spec_helper"

describe AsciidoctorDiagram::DiagramBlockProcessor do
  describe "#initialize" do
    it "sets the tool name" do
      proc = AsciidoctorDiagram::DiagramBlockProcessor.new("plantuml")
      proc.tool_name.should eq("plantuml")
      proc.name.should eq("plantuml")
    end

    it "accepts all supported diagram types" do
      AsciidoctorDiagram::DIAGRAM_NAMES.each do |name|
        proc = AsciidoctorDiagram::DiagramBlockProcessor.new(name)
        proc.tool_name.should eq(name)
      end
    end
  end

  describe "contexts" do
    it "supports listing, literal, open, and paragraph contexts" do
      proc = AsciidoctorDiagram::DiagramBlockProcessor.new("plantuml")
      contexts = proc.contexts
      contexts.should contain(:listing)
      contexts.should contain(:literal)
      contexts.should contain(:open)
      contexts.should contain(:paragraph)
    end
  end
end

describe AsciidoctorDiagram::DiagramExtensionGroup do
  it "can be instantiated" do
    group = AsciidoctorDiagram::DiagramExtensionGroup.new
    group.should be_a(Asciidoctor::Extensions::Group)
  end
end
