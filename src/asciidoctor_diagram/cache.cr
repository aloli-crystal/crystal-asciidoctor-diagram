require "digest/sha256"

module AsciicrystalDiagram
  # File-based cache for generated diagram images.
  #
  # Uses SHA256 of the diagram source to avoid regenerating identical diagrams.
  # Cache files are stored in a `.asciidoctor/diagram` directory relative to
  # the output directory.
  class Cache
    getter cache_dir : String

    def initialize(@cache_dir : String = ".asciidoctor/diagram")
      Dir.mkdir_p(@cache_dir) unless Dir.exists?(@cache_dir)
    end

    # Compute the SHA256 hex digest of the given source string.
    def self.hash_key(source : String) : String
      Digest::SHA256.hexdigest(source)
    end

    # Return the cache file path for the given key and format.
    def cache_path(key : String, format : String) : String
      File.join(@cache_dir, "#{key}.#{format}")
    end

    # Check whether a cached image exists for the given source and format.
    def hit?(source : String, format : String) : Bool
      key = self.class.hash_key(source)
      File.exists?(cache_path(key, format))
    end

    # Retrieve cached image data. Returns nil if not cached.
    def get(source : String, format : String) : String?
      key = self.class.hash_key(source)
      path = cache_path(key, format)
      if File.exists?(path)
        File.read(path)
      end
    end

    # Store image data in the cache. Returns the cache file path.
    def put(source : String, format : String, data : String) : String
      key = self.class.hash_key(source)
      path = cache_path(key, format)
      File.write(path, data)
      path
    end

    # Store image data (bytes) in the cache. Returns the cache file path.
    def put(source : String, format : String, data : Bytes) : String
      key = self.class.hash_key(source)
      path = cache_path(key, format)
      File.write(path, data)
      path
    end

    # Clear the entire cache directory.
    def clear! : Nil
      if Dir.exists?(@cache_dir)
        Dir.each_child(@cache_dir) do |entry|
          path = File.join(@cache_dir, entry)
          File.delete(path) if File.file?(path)
        end
      end
    end
  end
end
