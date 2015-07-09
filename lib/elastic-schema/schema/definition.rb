module ElasticSchema::Schema

  class Definition

    SchemaConflict = Class.new(StandardError)
    NoIndexDefined = Class.new(StandardError)

    @@definitions = {}

    def initialize(&block)
      @_field_chain = []

      instance_eval(&block)

      if @@definitions[definition_id]
        fail SchemaConflict.new("There is already a schema definition for #{definition_id}")
      end

      @@definitions[definition_id] = self
    end

    def analysis(name)
      @settings = Settings.new(analysis: name)
    end

    def type(name, &block)
      fail NoIndexDefined.new("There is not index defined yet.") if index.nil?
      index.type(name, &block)
    end

    def index(name = nil)
      return @index if name.nil?
      @index = Index.new(name, self)
    end

    def to_hash
      #main_hash = {}
      #main_hash.update(@mapping.to_hash) if @mapping
      #main_hash.update(@settings.to_hash) if @settings && @settings.to_hash.any?
      { index.name => index }
    end

    def self.definitions
      @@definitions
    end

    private

    def definition_id
      index.name
    end
  end

end
