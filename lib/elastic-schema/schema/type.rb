module ElasticSchema::Schema
  class Type
    attr_reader :name, :index

    def initialize(name, index, &block)
      @name  = name
      @index = index
      instance_eval(&block)
    end

    def field(field_name, type = :object, opts = {}, &block)
      @mapping ||= Mapping.new(index.name, name)
      field_name = field_name.to_s
      field_type = field_type.to_s

      @_field_chain << field_name
      @mapping.add_field(@_field_chain.join("."), field_type, opts)
      instance_eval(&block) if block_given?
      @_field_chain.pop
    end
  end
end
