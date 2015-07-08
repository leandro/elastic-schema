module ElasticSchema::Schema

  class Type

    attr_reader :name, :types

    def initialize(name)
      @name  = name
      @types = []
    end

  end

end
