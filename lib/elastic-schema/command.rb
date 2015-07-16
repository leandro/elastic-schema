module ElasticSchema

  class Command

    attr_reader :client, :root, :schema_dir, :options, :schema_file, :analysis_file,
                :bulk_size

    def initialize(options)
      @options       = options
      @client        = Elasticsearch::Client.new(host: options[:host])
      @root          = File.expand_path(options[:root])
      @schema_dir    = File.join(@root, options[:schema_dir]) if options[:schema_dir]
      @schema_file   = File.join(@root, options[:schema_file]) if options[:schema_file]
      @analysis_file = File.join(@root, options[:analysis_file]) if options[:analysis_file]
      @bulk_size     = options[:bulk_size]
    end

    def run(command)
      send(command)
    end

    private

    # Creates the indices/types and raise an exception if the any of the indices/types already exists
    def create
      opts = { client: client, analysis_files: analysis_files, schema_files: schema_files }
      opts.update(bulk_size: bulk_size) if bulk_size
      Schema::Migration.new(opts).load_definitions.run
    end

    def schema_files
      (schema_dir ? Dir[schema_pattern] : [schema_file]).compact
    end

    def analysis_files
      (schema_dir ? Dir[analysis_pattern] : [analysis_file]).compact
    end

    def schema_pattern
      File.join(schema_dir, '*.schema.rb')
    end

    def analysis_pattern
      File.join(schema_dir, '{analysis.rb,*.analysis.rb}')
    end
  end
end
