module ElasticSchema::Schema

  class Mappings
    TypeAlreadyDefined = Class.new(StandardError)

    attr_reader :index, :types

    def initialize(index)
      @index = index
      @types = {}
    end

    def type(name, &block)
      if types.has_key?(name)
        fail TypeAlreadyDefined.new("There is already a schema defined for ype '#{name}' in index '#{name}'.")
      end
      @types[name] = Type.new(name, self, &block)
    end

    def add_field(field_name, type = 'object', attrs = {})
      full_name  = field_name
      field_name = full_name.split('.').last
      parent(full_name) << Field.new(field_name, type, attrs.merge(parent: self))
    end

    def find(field_name)
      field_name.split('.').inject(fields) { |field_set, piece_name| field_set.find(piece_name) }
    end

    def full_name
      "#{index}/#{type}"
    end

    def to_hash
      { "mappings" => { type => fields.to_hash } }
    end

    private

    def parent(field_name)
      nested_names = field_name.split('.')
      nested_names.size == 1 ? fields : find(nested_names[0..-2].join('.')).children
    end
  end

end
