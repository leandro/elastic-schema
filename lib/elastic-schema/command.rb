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
      load_schemas
    end

    def schema_files
      schema_pattern = File.join(schema_dir, '*.schema.rb')
      Dir[schema_pattern].inject([]) { |files, schema_file| files << schema_file }
    end

    def load_schemas
      schema_files.each { |schema_file| require schema_file }

      loaded_schemas.each do |schema_id, schema|
        index, type = schema_id.split('/')
        body        = schema.mapping.to_hash
        p body
        #client.indices.create(index: index) unless client.indices.exists(index: index)
        #client.indices.put_mapping(index: index, type: type, body: body)
      end
    end

    def loaded_schemas
      ElasticSchema::Schema::Definition.definitions
    end
  end
end
