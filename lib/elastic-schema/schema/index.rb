module ElasticSchema::Schema
  class Index
    attr_reader :name, :definition, :mappings

    def initialize(name, definition)
      @name       = name
      @definition = definition
    end

    def type(type_name, &block)
      @mappings ||= Mappings.new(name, type_name)
      mappings.type(type_name, &block)
    end
  end
end
