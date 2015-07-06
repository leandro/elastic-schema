module ElasticSchema::Schema

  class Definition

    SchemaConflict = Class.new(StandardError)

    @@definitions = {}

    def initialize(&block)
      @_field_chain = []

      instance_eval(&block)

      if @@definitions[schema_id]
        fail SchemaConflict.new("There is already a schema definition for #{schema_id}")
      end

      @@definitions[schema_id] = self
    end

    def analysis(name)
      @settings = Settings.new(analysis: name)
    end

    def index(name = nil)
      return if @index
      @index = name
    end

    def type(name = nil)
      return if @type
      @type = name
    end

    def field(name, type = :object, opts = {}, &block)
      @mapping ||= Mapping.new(@index, @type)
      name       = name.to_s
      type       = type.to_s

      @_field_chain << name
      @mapping.add_field(@_field_chain.join("."), type, opts)
      instance_eval(&block) if block_given?
      @_field_chain.pop
    end

    def to_hash
      main_hash = {}
      main_hash.update(@mapping.to_hash) if @mapping
      main_hash.update(@settings.to_hash) if @settings && @settings.to_hash.any?
      { @index => main_hash }
    end

    def self.definitions
      @@definitions
    end

    private

    def schema_id
      @_schema_id ||= "#{@index}/#{@type}"
    end
  end

end
