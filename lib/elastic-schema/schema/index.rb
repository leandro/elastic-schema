module ElasticSchema::Schema

  class Index

    attr_reader :name, :types

    def initialize(name)
      @name  = name
      @types = []
    end

  end

end
