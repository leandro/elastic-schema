module ElasticSchema::Schema

  class Migration

    attr_reader :schema_files, :client, :actual_schemas, :timestamp, :analysis_files

    def initialize(client, analysis_files, schema_files)
      @client         = client
      @analysis_files = analysis_files
      @schema_files   = schema_files
      @actual_schemas = {}
      @timestamp      = Time.new.to_i
    end

    def load_definitions
      analysis_files.each { |schema_file| require schema_file }
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
        body        = schema.to_hash.values.first

        if type_exists?(index, type)
          update_mapping(index, type, body)
        else
          new_index = new_index_name(index)
          create_type(new_index, type, body)
          alias_index(new_index, index)
        end
      end
    end

    def update_mapping(index, type, schema)
      if must_reindex?(index, type)
        migrate_data(index, type, schema)
      else
        begin
          # We firstly try to update the index as it is, in case of solely new
          # fields being added
          put_mapping(index, type, schema)
        rescue Elasticsearch::Transport::Transport::Errors::BadRequest
          # We get here if we get MergeMappingException from Elasticsearch
          migrate_data(index, type, schema)
        end
      end
    end

    # Migrates data from index/type to a new index/type and create an alias to it
    def migrate_data(index, type, schema)
      new_index = new_index_name(index)
      create_type(new_index, type, schema)
      copy_documents(type, index, new_index)
      delete_index_with_same_name_as_alias(index)
      alias_index(new_index, index)
      delete_older_indices(index)
    end

    def alias_index(index, alias_name)
      puts "Creating alias '#{alias_name}' to index '#{index}'"
      client.indices.put_alias(index: index, name: alias_name)
    end

    def delete_older_indices(alias_name)
      older_indices = indices_from_alias(alias_name).keys - [new_index_name(alias_name)]
      older_indices.each { |index| delete_index(index) if index_exists?(index) }
    end

    def delete_index_with_same_name_as_alias(alias_name)
      delete_index(alias_name) if !alias_exists?(alias_name) && index_exists?(alias_name)
    end

    def copy_documents(type, old_index, new_index)
      return unless (doc_count = documents_count(old_index, type)) > 0

      puts "Migrating #{doc_count} documents from type '#{type}' in index '#{old_index}' to index '#{new_index}'"

      result        = client.search index: old_index, type: type, search_type: 'scan', scroll: '5m', size: 1000
      bulk_template = { index: { _index: new_index, _type: type } }

      while (result = client.scroll(scroll_id: result['_scroll_id'], scroll: '5m')) && (docs = result['hits']['hits']).any?
        body = docs.map do |document|
                 bulk_item = bulk_template.dup
                 bulk_item[:index].update(_id: document['_id'], data: document['_source'])
                 bulk_item
               end
        client.bulk(body: body)
      end
    end

    def must_reindex?(index, type)
      new_mapping = schemas["#{index}/#{type}"].to_hash.values.first['mappings'][type]['properties'] rescue {}
      old_mapping = actual_schemas["#{index}/#{type}"].values.first['mappings'][type]['properties']
      new_mapping_fields = extract_field_names(new_mapping)
      old_mapping_fields = extract_field_names(old_mapping)
      (old_mapping_fields & new_mapping_fields) != old_mapping_fields
    end

    def extract_field_names(mapping, name = '')
      mapping.inject([]) do |names, (key, value)|
        full_name = name.empty? ? key : "#{name}.#{key}"

        if value.is_a?(Hash)
          if value.keys == %w(properties) || value.has_key?('type') && %w(nested object).include?(value['type'])
            value     = value['properties']
            full_name = name.empty? ? key : name
          end
          expanded_names = extract_field_names(value, full_name)
        else
          full_name      = name
          expanded_names = full_name
        end

        names.concat(Array(expanded_names))
      end.uniq.sort
    end

    def documents_count(index, type)
      client.count(index: index, type: type)['count']
    end

    def indices_from_alias(alias_name)
      client.indices.get_alias(name: alias_name)
    end

    def delete_alias(alias_name)
      puts "Deleting index alias '#{alias_name}'"
      client.indices.delete_alias(alias_name)
    end

    def delete_index(index)
      puts "Deleting index '#{index}'"
      client.indices.delete(index: index)
    end

    def create_index(index, settings)
      puts "Creating index '#{index}'"
      client.indices.create(index: index, body: { settings: settings })
    end

    def create_type(index, type, schema)
      create_index(index, schema['settings']) unless index_exists?(index)
      put_mapping(index, type, schema['mappings'])
    end

    def alias_exists?(alias_name)
      client.indices.exists_alias(name: alias_name)
    end

    def index_exists?(index)
      client.indices.exists(index: index)
    end

    def type_exists?(index, type)
      client.indices.exists_type(index: index, type: type)
    end

    def put_mapping(index, type, mapping)
      puts "Creating/updating type '#{type}' in index/alias '#{index}'"
      client.indices.put_mapping(index: index, type: type, body: mapping)
    end

    def new_index_name(index)
      "#{index}_v#{timestamp}"
    end

    # Get all the index/type in ES that diverge from the definitions
    def types_to_update
      schemas.select do |schema_id, schema|
        index, type    = schema_id.split('/')
        current_schema = fetch_mapping(index, type)

        if current_schema.any?
          current_schema.values.first.update(fetch_settings(index).values.first)
        end

        @actual_schemas[schema_id] = current_schema
        !equal_schemas?(schema.to_hash.values.first, current_schema.values.first)
      end
    end

    def equal_schemas?(schema_1, schema_2)
      equal_mappings?(schema_1, schema_2) && equal_settings?(schema_1, schema_2)
    end

    def equal_mappings?(schema_1, schema_2)
      schema_1['mappings'] == schema_2['mappings']
    end

    def equal_settings?(schema_1, schema_2)
      settings_1 = schema_1['settings']['index']['analysis'] rescue {}
      settings_2 = schema_2['settings']['index']['analysis'] rescue {}
      settings_1 == settings_2
    end

    def fetch_settings(index)
      begin
        client.indices.get_settings(index: index)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        {}
      end
    end

    def fetch_mapping(index, type)
      begin
        client.indices.get_mapping(index: real_index_for(index), type: type)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        {}
      end
    end

    # For cases where {index} might be an alias instead
    def real_index_for(index)
      begin
        client.indices.get_alias(name: index).keys.first
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        index
      end
    end

    def schemas
      @schemas ||= ElasticSchema::Schema::Definition.definitions
    end
  end

end
