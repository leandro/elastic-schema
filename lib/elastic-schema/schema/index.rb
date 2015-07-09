module ElasticSchema::Schema
  class Index
    TypeAlreadyDefined = Class.new(StandardError)

    attr_reader :name, :types, :definition

    def initialize(name, definition)
      @name       = name
      @definition = definition
      @types      = {}
    end

    def type(name, &block)
      if types.has_key?(name)
        fail TypeAlreadyDefined.new("There is already a schema defined for ype '#{name}' in index '#{name}'.")
      end
      @types[name] = Type.new(name, self, &block)
    end
  end
end
