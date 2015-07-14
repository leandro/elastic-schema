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
      schemas_to_update = types_to_update
      total_schemas     = schemas.size
      needs_update      = schemas_to_update.size

      if total_schemas > 0
        if needs_update < 1
          puts "Woo-hoo! Everything is already up-to-date!"
        else
          puts "Initiating schema updates: #{needs_update} out of #{total_schemas} will be updated."
        end
      else
        puts "There are no schemas to be processed in the provided directory."
      end

      create_or_update_indices(schemas_to_update)
    end

    private

    def create_or_update_indices(selected_schemas)
      selected_schemas.each do |index_name, schema|
        index_body = schema.index.to_hash.values.first

        if index_exists?(index_name)
          if must_create_new_index?(schema, index_name)
            migrate_data(index_name, index_body)
          else
            types = updatable_or_creatable_types(schema, index_name)
            create_or_update_types(schema, types)
          end
        else
          new_index = new_index_name(index_name)
          create_index(new_index, index_body)
          alias_index(new_index, index_name)
        end
      end
    end

    def create_or_update_types(schema, types)
      mappings = schema.index.mappings.to_hash['mappings']

      types.each do |type|
        mapping = mappings[type]
        put_mapping(schema.index.name, type, { type => mapping })
      end
    end

    # Migrates data from index/type to a new index/type and create an alias to it
    def migrate_data(index_name, index_body)
      new_index = new_index_name(index_name)
      create_index(new_index, index_body)
      copy_all_documents_between_indices(index_name, new_index)
      delete_index_with_same_name_as_alias(index_name)
      alias_index(new_index, index_name)
      delete_older_indices(index_name)
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

    def copy_all_documents_between_indices(old_index, new_index)
      types = actual_schemas[old_index].values.first['mappings'].keys
      types.each { |type| copy_documents_for_type(type, old_index, new_index) }
    end

    def copy_documents_for_type(type, old_index, new_index)
      return unless (doc_count = documents_count(old_index, type)) > 0

      puts "Migrating #{doc_count} documents from type '#{type}' in index '#{old_index}' to index '#{new_index}'"

      result         = client.search index: old_index, type: type, search_type: 'scan', scroll: '1m', size: 1000
      alias_name     = new_index.split("_")[0..-2].join("_")
      fields_filter  = fields_whilelist(alias_name, type)

      while (result = client.scroll(scroll_id: result['_scroll_id'], scroll: '1m')) && (docs = result['hits']['hits']).any?
        body = docs.map do |document|
                 bulk_item = { index: { _index: new_index, _type: type } }
                 source    = document['_source'].deep_slice(*fields_filter)
                 bulk_item[:index].update(_id: document['_id'], data: source)
                 bulk_item
               end
        client.bulk(body: body)
      end
    end

    def fields_whilelist(alias_name, type)
      mapping = schemas[alias_name].to_hash.values.first['mappings'][type]['properties']
      extract_field_names(mapping).map { |f| f.include?('.') ? f.split('.') : f }
    end

    def updatable_or_creatable_types(schema, index_name)
      old_mappings = actual_schemas[index_name].values.first['mappings']
      new_mappings = schema.index.mappings.to_hash['mappings']

      new_mappings.keys.select do |type|
        old_fields         = old_mappings[type]['properties'] rescue {}
        new_fields         = new_mappings[type]['properties']
        old_mapping_fields = extract_field_names(old_fields)
        new_mapping_fields = extract_field_names(new_fields)

        (new_mapping_fields - old_mapping_fields).any?
      end
    end

    def must_create_new_index?(schema, index)
      has_diverging_settings?(schema, index) || has_conflicting_mappings?(schema, index)
    end

    def has_conflicting_mappings?(schema, index)
      old_mappings = actual_schemas[index].values.first['mappings']
      new_mappings = schema.index.mappings.to_hash['mappings']

      old_mappings.each do |type, old_mapping|
        old_fields = old_mapping['properties']
        new_fields = new_mappings[type]['properties'] rescue nil

        next if new_fields.nil?

        old_mapping_fields = extract_field_names(old_fields)
        new_mapping_fields = extract_field_names(new_fields)
        shared_fields      = old_mapping_fields & new_mapping_fields

        return true if shared_fields != old_mapping_fields

        old_mapping_fields = old_mapping_fields.map do |full_name|
          full_name = full_name.split('.').join('.properties.').split('.')
          full_name.size == 1 ? full_name.first : full_name
        end
        new_mapping_fields = new_mapping_fields.map do |full_name|
          full_name = full_name.split('.').join('.properties.').split('.')
          full_name.size == 1 ? full_name.first : full_name
        end

        return true if old_fields.deep_slice(*old_mapping_fields) != new_fields.deep_slice(*new_mapping_fields)
      end

      return false
    end

    # For now we're only comparing analysis settings
    def has_diverging_settings?(schema, index)
      old_settings = actual_schemas[index].values.first['settings']['index']['analysis'] rescue {}
      new_settings = schema.index.settings.to_hash['settings']['index']['analysis'] rescue {}
      new_settings != old_settings
    end

    def extract_field_names(mapping, name = '')
      mapping.inject([]) do |names, (key, value)|
        full_name = name.empty? ? key : "#{name}.#{key}"

        if value.is_a?(Hash)
          full_name = name if key == 'properties'
          expanded_names = extract_field_names(value, full_name)
        else
          expanded_names = name
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

    def delete_index(index)
      puts "Deleting index '#{index}'"
      client.indices.delete(index: index)
    end

    def create_index(index, body)
      puts "Creating index '#{index}'"

      types = body["mappings"].keys rescue []
      types.each { |type| puts "Creating type '#{type}' in index '#{index}'" }

      client.indices.create(index: index, body: body)
    end

    def alias_exists?(alias_name)
      client.indices.exists_alias(name: alias_name)
    end

    def index_exists?(index)
      client.indices.exists(index: index)
    end

    def put_mapping(index, type, mapping)
      puts "Creating/updating type '#{type}' in index '#{index}'"
      client.indices.put_mapping(index: index, type: type, body: mapping)
    end

    def new_index_name(index)
      "#{index}_v#{timestamp}"
    end

    # Get all the index/type in ES that diverge from the definitions
    def types_to_update
      schemas.select do |index_name, schema|
        current_schema              = fetch_index(index_name)
        @actual_schemas[index_name] = current_schema
        !has_same_index_structures?(schema.to_hash.values.first, current_schema.values.first || {})
      end
    end

    def has_same_index_structures?(old_index_body, new_index_body)
      old_index_body = old_index_body.deep_slice('mappings', %w(settings index analysis)) rescue {}
      new_index_body = new_index_body.deep_slice('mappings', %w(settings index analysis)) rescue {}
      old_index_body == new_index_body
    end

    def fetch_index(index)
      begin
        client.indices.get(index: index)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        {}
      end
    end

    def schemas
      @schemas ||= ElasticSchema::Schema::Definition.definitions
    end
  end
end
