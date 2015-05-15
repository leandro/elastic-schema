module ElasticSchema

  class Command

    attr_reader :client, :root, :schema_dir, :schema_files

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
      load_schemas
    end

    def get_schemas
      @schema_files  = []
      schema_pattern = File.join(schema_dir, '*.schema.rb')

      Dir[schema_pattern].each do |schema_file|
        @schema_files << schema_file
      end

      @schema_files
    end

    def load_schemas
      get_schemas.each do |schema_file|
        require schema_file
      end
    end
  end
end
