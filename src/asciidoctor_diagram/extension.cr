module AsciicrystalDiagram
  # A block processor that handles a specific diagram type.
  #
  # When a block with the diagram name is encountered (e.g. `[plantuml]`),
  # this processor:
  # 1. Reads the diagram source from the block content
  # 2. Calls the external tool to generate an image
  # 3. Returns either an inline SVG (pass block) or an image block
  class DiagramBlockProcessor < Asciicrystal::Extensions::BlockProcessor
    getter tool_name : String

    def initialize(@tool_name : String)
      super(@tool_name, {
        "contexts"      => Set{:listing, :literal, :open, :paragraph},
        "content_model" => :simple,
      } of String => String | Bool | Int32 | Array(String) | Set(Symbol) | Symbol)
    end

    def process(parent : Asciicrystal::AbstractBlock, reader : Asciicrystal::Reader, attributes : Hash(String, String)) : Asciicrystal::AbstractBlock?
      doc = parent.document
      source = reader.source_lines.join("\n")
      return nil if source.strip.empty?

      # Determine output format: attribute on block, or document attribute, or default svg
      format = attributes["format"]? ||
               doc.attributes["diagram-format"]? ||
               "svg"

      # Resolve tool path from document attributes
      spec = TOOL_SPECS[@tool_name]?
      tool_path = if spec
                    doc.attributes[spec.path_attr]? || spec.default_cmd
                  else
                    @tool_name
                  end

      # Set up cache
      cache_dir = doc.attributes["diagram-cachedir"]? || File.join(doc.attributes["outdir"]? || ".", ".asciidoctor", "diagram")
      cache = Cache.new(cache_dir)

      # Generate the diagram
      begin
        data = Generator.generate(@tool_name, source, format, tool_path: tool_path, cache: cache)
      rescue ex : Generator::ToolError
        # On error, return an admonition-style warning block
        warn_msg = "Failed to generate #{@tool_name} diagram: #{ex.message}"
        STDERR.puts warn_msg
        return create_paragraph(parent, warn_msg, {} of String => String)
      end

      # Determine target filename for the image
      target_name = attributes["target"]? || Cache.hash_key(source)
      target_file = "#{target_name}.#{format}"

      if format == "svg" && !attributes.has_key?("opts-inline")
        # Check for inline option: embed SVG directly
        inline_svg = attributes["opt-inline"]? || doc.attributes["diagram-svg-type"]? == "inline"
        if inline_svg
          return create_pass_block(parent, data, {} of String => String)
        end
      end

      # Write image to output directory
      images_dir = doc.attributes["imagesoutdir"]? || doc.attributes["imagesdir"]? || ""
      outdir = doc.attributes["outdir"]? || doc.attributes["to_dir"]? || "."
      images_output_dir = if images_dir.starts_with?("/") || images_dir.starts_with?(".")
                            images_dir
                          elsif images_dir.empty?
                            outdir
                          else
                            File.join(outdir, images_dir)
                          end
      Dir.mkdir_p(images_output_dir) unless Dir.exists?(images_output_dir)
      output_path = File.join(images_output_dir, target_file)
      File.write(output_path, data)

      # Build image block attributes
      img_attrs = {
        "target" => target_file,
        "alt"    => attributes["alt"]? || @tool_name.capitalize + " diagram",
      } of String => String
      img_attrs["width"] = attributes["width"] if attributes.has_key?("width")
      img_attrs["height"] = attributes["height"] if attributes.has_key?("height")
      img_attrs["title"] = attributes["title"] if attributes.has_key?("title")
      img_attrs["role"] = attributes["role"] if attributes.has_key?("role")

      create_image_block(parent, img_attrs)
    end
  end

  # Extension group that registers all diagram block processors.
  class DiagramExtensionGroup < Asciicrystal::Extensions::Group
    def activate(registry : Asciicrystal::Extensions::Registry) : Nil
      DIAGRAM_NAMES.each do |name|
        registry.block(DiagramBlockProcessor.new(name), name)
      end
    end
  end

  # Register the extension group globally so that it activates automatically
  # when asciicrystal-diagram is required.
  Asciicrystal::Extensions.register(:diagram, DiagramExtensionGroup)
end
