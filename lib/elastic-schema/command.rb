module ElasticSchema

  class Command

    attr_reader :client, :root, :schema_dir

    def initialize(host, root, schema_dir)
      @client     = Elasticsearch::Client.new(host: host)
      @root       = File.expand_path(root)
      @schema_dir = File.join(@root, schema_dir)
    end

    def run(command)
      send(command)
    end

    private

    # Creates the indices/types and raise an exception if the any of the indices/types already exists
    def create
      Schema::Migration.new(client, analysis_files, schema_files).load_definitions.run
    end

    def schema_files
      Dir[schema_pattern].inject([]) { |files, schema_file| files << schema_file }
    end

    def analysis_files
      Dir[analysis_pattern].inject([]) { |files, analysis_file| files << analysis_file }
    end

    def schema_pattern
      File.join(schema_dir, '*.schema.rb')
    end

    def analysis_pattern
      File.join(schema_dir, '{analysis.rb,*.analysis.rb}')
    end
  end
end
