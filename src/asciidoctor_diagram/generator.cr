module AsciidoctorDiagram
  # Describes the input file extension and output handling for a diagram tool.
  record ToolSpec,
    # The document attribute name for the tool path (e.g. "plantuml-path").
    path_attr : String,
    # The default command name if the attribute is not set.
    default_cmd : String,
    # The input file extension (e.g. ".puml").
    input_ext : String,
    # A proc that builds the command-line arguments.
    # Receives: tool_path, input_file, output_file, format.
    build_args : Proc(String, String, String, String, Array(String))

  # Registry of all supported diagram tools and their specifications.
  TOOL_SPECS = {
    "plantuml" => ToolSpec.new(
      path_attr: "plantuml-path",
      default_cmd: "plantuml",
      input_ext: ".puml",
      build_args: ->(cmd : String, input : String, output : String, fmt : String) {
        [cmd, "-t#{fmt}", "-pipe", "<", input, ">", output] # simplified; actual uses -pipe or file
      }
    ),
    "mermaid" => ToolSpec.new(
      path_attr: "mermaid-path",
      default_cmd: "mmdc",
      input_ext: ".mmd",
      build_args: ->(cmd : String, input : String, output : String, fmt : String) {
        [cmd, "-i", input, "-o", output, "-e", fmt]
      }
    ),
    "ditaa" => ToolSpec.new(
      path_attr: "ditaa-path",
      default_cmd: "ditaa",
      input_ext: ".ditaa",
      build_args: ->(cmd : String, input : String, output : String, fmt : String) {
        args = [cmd, input, output]
        args << "--svg" if fmt == "svg"
        args
      }
    ),
    "graphviz" => ToolSpec.new(
      path_attr: "graphviz-path",
      default_cmd: "dot",
      input_ext: ".dot",
      build_args: ->(cmd : String, input : String, output : String, fmt : String) {
        [cmd, "-T#{fmt}", "-o", output, input]
      }
    ),
    "dot" => ToolSpec.new(
      path_attr: "graphviz-path",
      default_cmd: "dot",
      input_ext: ".dot",
      build_args: ->(cmd : String, input : String, output : String, fmt : String) {
        [cmd, "-T#{fmt}", "-o", output, input]
      }
    ),
    "blockdiag" => ToolSpec.new(
      path_attr: "blockdiag-path",
      default_cmd: "blockdiag",
      input_ext: ".diag",
      build_args: ->(cmd : String, input : String, output : String, fmt : String) {
        [cmd, "-T#{fmt}", "-o", output, input]
      }
    ),
    "seqdiag" => ToolSpec.new(
      path_attr: "seqdiag-path",
      default_cmd: "seqdiag",
      input_ext: ".diag",
      build_args: ->(cmd : String, input : String, output : String, fmt : String) {
        [cmd, "-T#{fmt}", "-o", output, input]
      }
    ),
    "actdiag" => ToolSpec.new(
      path_attr: "actdiag-path",
      default_cmd: "actdiag",
      input_ext: ".diag",
      build_args: ->(cmd : String, input : String, output : String, fmt : String) {
        [cmd, "-T#{fmt}", "-o", output, input]
      }
    ),
    "nwdiag" => ToolSpec.new(
      path_attr: "nwdiag-path",
      default_cmd: "nwdiag",
      input_ext: ".diag",
      build_args: ->(cmd : String, input : String, output : String, fmt : String) {
        [cmd, "-T#{fmt}", "-o", output, input]
      }
    ),
    "umlet" => ToolSpec.new(
      path_attr: "umlet-path",
      default_cmd: "umlet",
      input_ext: ".uxf",
      build_args: ->(cmd : String, input : String, output : String, fmt : String) {
        [cmd, "-action=convert", "-format=#{fmt}", "-filename=#{input}", "-output=#{output}"]
      }
    ),
    "svgbob" => ToolSpec.new(
      path_attr: "svgbob-path",
      default_cmd: "svgbob",
      input_ext: ".bob",
      build_args: ->(cmd : String, input : String, output : String, fmt : String) {
        [cmd, input, "-o", output]
      }
    ),
    "pikchr" => ToolSpec.new(
      path_attr: "pikchr-path",
      default_cmd: "pikchr",
      input_ext: ".pikchr",
      build_args: ->(cmd : String, input : String, output : String, fmt : String) {
        [cmd, "--svg-only", input]
      }
    ),
    "d2" => ToolSpec.new(
      path_attr: "d2-path",
      default_cmd: "d2",
      input_ext: ".d2",
      build_args: ->(cmd : String, input : String, output : String, fmt : String) {
        [cmd, input, output]
      }
    ),
    "lilypond" => ToolSpec.new(
      path_attr: "lilypond-path",
      default_cmd: "lilypond",
      input_ext: ".ly",
      build_args: ->(cmd : String, input : String, output : String, fmt : String) {
        args = [cmd, "--output=#{File.dirname(output)}/#{File.basename(output, File.extname(output))}"]
        args << "--svg" if fmt == "svg"
        args << "--png" if fmt == "png"
        args << input
        args
      }
    ),
    "gnuplot" => ToolSpec.new(
      path_attr: "gnuplot-path",
      default_cmd: "gnuplot",
      input_ext: ".gnuplot",
      build_args: ->(cmd : String, input : String, output : String, fmt : String) {
        [cmd, "-e", "set terminal #{fmt}; set output '#{output}'", input]
      }
    ),
  }

  # All supported diagram block names (used for registering block processors).
  DIAGRAM_NAMES = TOOL_SPECS.keys

  # The Generator runs external diagram tools and manages temp files.
  class Generator
    # Error raised when an external tool fails.
    class ToolError < Exception; end

    # Generate a diagram image from source code.
    #
    # Returns the image data as a String (file contents).
    #
    # Parameters:
    #   tool_name - one of the DIAGRAM_NAMES (e.g. "plantuml", "mermaid")
    #   source    - the diagram source code
    #   format    - output format ("svg" or "png")
    #   tool_path - optional override for the tool command path
    #   cache     - optional Cache instance for caching
    def self.generate(tool_name : String, source : String, format : String = "svg",
                      tool_path : String? = nil, cache : Cache? = nil) : String
      # Check cache first
      if cache && cache.hit?(source, format)
        return cache.get(source, format).not_nil!
      end

      spec = TOOL_SPECS[tool_name]? || raise ToolError.new("Unknown diagram tool: #{tool_name}")
      cmd = tool_path || spec.default_cmd

      # Create temp files
      tmp_dir = Dir.tempdir
      key = Cache.hash_key(source)
      input_file = File.join(tmp_dir, "asciidoctor-diagram-#{key}#{spec.input_ext}")
      output_file = File.join(tmp_dir, "asciidoctor-diagram-#{key}.#{format}")

      begin
        File.write(input_file, source)

        run_tool(cmd, spec, input_file, output_file, format, tool_name)

        # Some tools (pikchr) write to stdout; handle that
        data = if File.exists?(output_file)
                 File.read(output_file)
               else
                 raise ToolError.new("#{tool_name}: output file not generated at #{output_file}")
               end

        # Store in cache
        cache.put(source, format, data) if cache

        data
      ensure
        File.delete?(input_file)
        File.delete?(output_file)
      end
    end

    # Run the external tool process.
    private def self.run_tool(cmd : String, spec : ToolSpec, input_file : String,
                              output_file : String, format : String, tool_name : String) : Nil
      case tool_name
      when "plantuml"
        # PlantUML: use -pipe mode to read stdin and write stdout
        run_plantuml(cmd, input_file, output_file, format)
      when "pikchr"
        # Pikchr outputs SVG to stdout
        run_pikchr(cmd, input_file, output_file)
      else
        # General case: build args and run
        args = spec.build_args.call(cmd, input_file, output_file, format)
        executable = args.shift
        status = Process.run(executable, args: args, error: Process::Redirect::Pipe) do |proc|
          err = proc.error.gets_to_end
          proc.wait
          unless proc.wait.success?
            raise ToolError.new("#{tool_name} failed (exit #{proc.wait.exit_code}): #{err}")
          end
        end
      end
    end

    # PlantUML-specific execution: uses -pipe for stdin/stdout.
    private def self.run_plantuml(cmd : String, input_file : String, output_file : String, format : String) : Nil
      source = File.read(input_file)
      args = ["-t#{format}", "-pipe"]
      # If cmd contains "java" it might be "java -jar plantuml.jar"
      # Otherwise, assume it's the plantuml wrapper script
      output = IO::Memory.new
      error = IO::Memory.new
      status = Process.run(cmd, args: args, input: IO::Memory.new(source), output: output, error: error)
      unless status.success?
        raise ToolError.new("plantuml failed (exit #{status.exit_code}): #{error}")
      end
      File.write(output_file, output.to_s)
    end

    # Pikchr-specific execution: outputs SVG to stdout.
    private def self.run_pikchr(cmd : String, input_file : String, output_file : String) : Nil
      output = IO::Memory.new
      error = IO::Memory.new
      status = Process.run(cmd, args: ["--svg-only", input_file], output: output, error: error)
      unless status.success?
        raise ToolError.new("pikchr failed (exit #{status.exit_code}): #{error}")
      end
      File.write(output_file, output.to_s)
    end
  end
end
