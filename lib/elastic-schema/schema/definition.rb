module ElasticSchema::Schema

  class Definition

    FieldAlreadyDefined = Class.new(StandardError)
    SchemaConflict      = Class.new(StandardError)

    @@definitions = {}

    def initialize(&block)
      @index        = :_all
      @mapping      = {}
      @_field_chain = []

      instance_eval(&block)

      if @@definitions[schema_id]
        fail SchemaConflict.new("There is already a schema definition for #{schema_id}")
      end

      @@definitions[schema_id] = @mapping
      p @@definitions
    end

    def index(name)
      return if @index
      @index = name
    end

    def type(name)
      return if @type
      @type = name
    end

    def field(name, type = :object, opts = {}, &block)
      name    = name.to_s
      type    = type.to_s
      mapping = get_mapping

      @_field_chain << name

      if mapping[name]
        field_mapping = @_field_chain.join(".")
        fail FieldAlreadyDefined.new("The mapping for field #{field_mapping} has been already defined.")
      end

      initial_settings = type == 'object' ? {} : { 'type' => type }
      mapping[name]    = opts.inject(initial_settings) do |settings, (attr, value)|
        settings.update(attr.to_s => value.to_s)
      end

      instance_eval(&block) if block_given?

      @_field_chain.pop
    end

    private

    def schema_id
      @_schema_id ||= "#{@index}/#{@type}"
    end

    def get_mapping
      @_field_chain.inject(@mapping) do |final_mapping, field_name|
        final_mapping = final_mapping[field_name]
      end
    end

  end

end
