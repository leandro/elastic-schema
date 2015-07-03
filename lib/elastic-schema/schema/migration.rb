module ElasticSchema::Schema

  class Migration

    attr_reader :schema_files, :client, :actual_schemas

    def initialize(client, schema_files)
      @client         = client
      @schema_files   = schema_files
      @actual_schemas = {}
    end

    def load_definitions
      schema_files.each { |schema_file| require schema_file }
      self
    end

    def run
      create_or_update_types(types_to_update)
    end

    private

    def create_or_update_types(selected_schemas)
      selected_schemas.each do |schema_id, schema|
        index, type = schema_id.split('/')
        body        = schema.mapping.to_hash[index]['mappings']

        if type_exists?(index, type)
          update_mapping(index, type, body)
        else
          create_type(index, type, body)
        end
      end
    end

    def update_mapping(index, type, mapping)
      must_reindex?(index, type)
      begin
        # We firstly try to update the index as it is, in case of solely new
        # fields being added
        put_mapping(index, type, mapping)
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => exc
        # We get here if we get MergeMappingException from Elasticsearch
        timestamp = Time.new.to_i
        temp_type = "#{type}_v#{timestamp}"
      end
    end

    def must_reindex?(index, type)
      new_mapping_fields = extract_field_names(actual_schemas["#{index}/#{type}"][index]['mappings'][type]['properties'])
      old_mapping_fields = extract_field_names(schemas["#{index}/#{type}"][index]['mappings'][type]['properties'])
      (old_mapping_fields & new_mapping_fields) != old_mapping_fields
    end

    def extract_field_names(mapping, name = '')
      mapping.inject([]) do |names, (key, value)|
        full_name = name.empty? ? key : "#{name}.#{key}"

        if value.is_a?(Hash)
          value          = value['properties'] if value.keys == %w(properties)
          expanded_names = extract_field_names(value, full_name)
        else
          full_name      = name
          expanded_names = full_name
        end

        names.concat(Array(expanded_names))
      end.uniq.sort
    end

    def documents_count(index, type)
      client.count(index: index, type: type)
    end

    def create_index(index)
      client.indices.create(index: index)
    end

    def create_type(index, type, mapping)
      create_index(index) unless index_exists?(index)
      put_mapping(index, type, mapping)
    end

    def index_exists?(index)
      client.indices.exists(index: index)
    end

    def type_exists?(index, type)
      client.indices.exists_type(index: index, type: type)
    end

    def put_mapping(index, type, mapping)
      client.indices.put_mapping(index: index, type: type, body: mapping)
    end

    # Get all the index/type in ES that diverge from the definitions
    def types_to_update
      schemas.select do |schema_id, schema|
        index, type     = schema_id.split('/')
        current_mapping = begin
                            client.indices.get_mapping(index: index, type: type)
                          rescue Elasticsearch::Transport::Transport::Errors::NotFound => exc
                            {}
                          end
        @actual_schemas[schema_id] = current_mapping
        schema.mapping.to_hash != current_mapping
      end
    end

    def schemas
      @schemas ||= ElasticSchema::Schema::Definition.definitions
    end
  end

end
