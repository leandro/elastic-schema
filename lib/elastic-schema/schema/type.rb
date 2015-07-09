module ElasticSchema::Schema
  class Type
    attr_reader :name, :mappings, :fields

    def initialize(name, mappings, &block)
      @name     = name
      @mappings = mappings
      instance_eval(&block)
    end

    def field(field_name, field_type = nil, opts = {}, &block)
      fields << Field.new(field_name, field_type, opts, &block)
    end

    def fields
      @fields ||= FieldsSet.new(self)
    end

    def parent
      mappings
    end

    def to_hash
      { name => fields.to_hash }
    end
  end
end
