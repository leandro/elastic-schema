module ElasticSchema::Schema

  class Definition

    SchemaConflict = Class.new(StandardError)
    NoIndexDefined = Class.new(StandardError)

    @@definitions = {}

    def initialize(&block)
      instance_eval(&block)

      if @@definitions[definition_id]
        fail SchemaConflict.new("There is already a schema definition for #{definition_id}")
      end

      @@definitions[definition_id] = self
    end

    def analysis(name)
      fail NoIndexDefined.new("There is not index defined yet.") if index.nil?
      index.analysis(name)
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
      index.to_hash
    end

    def self.definitions
      @@definitions
    end

    private

    def definition_id
      index.name.to_s
    end
  end

end
