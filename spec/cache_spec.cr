require "./spec_helper"

describe AsciidoctorDiagram::Cache do
  cache_dir = File.join(SpecHelper::SPEC_OUTPUT_DIR, "cache_test")

  before_each do
    Dir.mkdir_p(cache_dir) unless Dir.exists?(cache_dir)
  end

  after_each do
    if Dir.exists?(cache_dir)
      Dir.each_child(cache_dir) do |entry|
        path = File.join(cache_dir, entry)
        File.delete(path) if File.file?(path)
      end
    end
  end

  describe ".hash_key" do
    it "returns a hex SHA256 digest" do
      key = AsciidoctorDiagram::Cache.hash_key("hello")
      key.should be_a(String)
      key.size.should eq(64)
      key.should match(/\A[0-9a-f]{64}\z/)
    end

    it "returns the same hash for the same input" do
      a = AsciidoctorDiagram::Cache.hash_key("test source")
      b = AsciidoctorDiagram::Cache.hash_key("test source")
      a.should eq(b)
    end

    it "returns different hashes for different inputs" do
      a = AsciidoctorDiagram::Cache.hash_key("source A")
      b = AsciidoctorDiagram::Cache.hash_key("source B")
      a.should_not eq(b)
    end
  end

  describe "#hit?" do
    it "returns false when nothing is cached" do
      cache = AsciidoctorDiagram::Cache.new(cache_dir)
      cache.hit?("some source", "svg").should be_false
    end

    it "returns true after putting data" do
      cache = AsciidoctorDiagram::Cache.new(cache_dir)
      cache.put("my diagram", "svg", "<svg></svg>")
      cache.hit?("my diagram", "svg").should be_true
    end

    it "returns false for a different format" do
      cache = AsciidoctorDiagram::Cache.new(cache_dir)
      cache.put("my diagram", "svg", "<svg></svg>")
      cache.hit?("my diagram", "png").should be_false
    end
  end

  describe "#get" do
    it "returns nil when nothing is cached" do
      cache = AsciidoctorDiagram::Cache.new(cache_dir)
      cache.get("absent", "svg").should be_nil
    end

    it "returns cached data" do
      cache = AsciidoctorDiagram::Cache.new(cache_dir)
      cache.put("diagram src", "svg", "<svg>test</svg>")
      cache.get("diagram src", "svg").should eq("<svg>test</svg>")
    end
  end

  describe "#put" do
    it "stores data and returns the cache path" do
      cache = AsciidoctorDiagram::Cache.new(cache_dir)
      path = cache.put("content", "png", "PNG DATA")
      path.should contain(cache_dir)
      path.should end_with(".png")
      File.exists?(path).should be_true
    end
  end

  describe "#clear!" do
    it "removes all cached files" do
      cache = AsciidoctorDiagram::Cache.new(cache_dir)
      cache.put("a", "svg", "data1")
      cache.put("b", "png", "data2")
      cache.clear!
      cache.hit?("a", "svg").should be_false
      cache.hit?("b", "png").should be_false
    end
  end

  describe "#cache_path" do
    it "constructs path from key and format" do
      cache = AsciidoctorDiagram::Cache.new(cache_dir)
      key = AsciidoctorDiagram::Cache.hash_key("src")
      path = cache.cache_path(key, "svg")
      path.should eq(File.join(cache_dir, "#{key}.svg"))
    end
  end
end
