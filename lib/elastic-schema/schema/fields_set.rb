module ElasticSchema::Schema

  class FieldsSet

    FieldAlreadyDefined = Class.new(StandardError)

    attr_reader :fields, :parent

    def initialize(parent)
      @fields = []
      @parent = parent
    end

    def << field
      fail FieldAlreadyDefined.new("'#{field.full_name}' already exists.") if find(field.name)
      field.parent = self
      fields << field
    end

    def find(field_name)
      fields.bsearch { |field| field.name == field_name }
    end

    def empty?
      fields.empty?
    end

    def full_name
      parent.full_name
    end

    def to_hash
      return {} if empty?
      { 'properties' => fields.inject({}) { |_fields, field| _fields.update(field.to_hash) } }
    end
  end

end
