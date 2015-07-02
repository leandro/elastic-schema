module ElasticSchema::Schema

  class Mapping

    attr_reader :index, :type

    def initialize(index, type)
      @index = index
      @type  = type
    end

    def add_field(field_name, type = 'object', attrs = {})
      full_name  = field_name
      field_name = full_name.split('.').last
      parent(full_name) << Field.new(field_name, type, attrs.merge(parent: self))
    end

    def find(field_name)
      field_name.split.inject(fields) { |field_set, piece_name| field_set.find(piece_name) }
    end

    def full_name
      "#{index}/#{type}"
    end

    def fields
      @fields ||= FieldsSet.new(self)
    end

    def to_hash
      { index => { "mappings" => { type => fields.to_hash } } }
    end

    private

    def parent(field_name)
      nested_names = field_name.split('.')
      begin
        nested_names.size == 1 ? fields : find(nested_names[0..-2].join('.')).children
      rescue
        p fields
        fail
      end
    end
  end

end
