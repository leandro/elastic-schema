module ElasticSchema::Schema

  class Mappings
    TypeAlreadyDefined = Class.new(StandardError)

    attr_reader :index, :types

    def initialize(index)
      @index = index
      @types = {}
    end

    def type(name, &block)
      name = name.to_s

      if types.has_key?(name)
        fail TypeAlreadyDefined.new("There is already a schema defined for type '#{name}' in index '#{name}'.")
      end

      @types[name] = Type.new(name, self, &block)
    end

    def parent
      index
    end

    def full_name
      parent.name
    end

    def to_hash
      types_hash = types.inject({}) { |_types_hash, (_, type)| _types_hash.update(type.to_hash) }
      { "mappings" => types_hash }
    end
  end
end
