module ElasticSchema::Schema
  class Type
    attr_reader :name, :mappings, :fields

    def initialize(name, mappings, &block)
      @name     = name
      @mappings = mappings
      instance_eval(&block)
    end

    def field(field_name, field_type = 'object', opts = {}, &block)
      fields << Field.new(field_name.to_s, field_type.to_s, opts, &block)
    end

    def fields
      @fields ||= FieldsSet.new(self)
    end

    def parent
      mappings
    end
  end
end
