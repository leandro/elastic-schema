module ElasticSchema::Schema
  class Index
    attr_reader :name, :definition, :mappings, :settings

    def initialize(name, definition)
      @name       = name
      @definition = definition
    end

    def analysis(name)
      @settings ||= Settings.new(self, analysis: name)
    end

    def type(type_name, &block)
      @mappings ||= Mappings.new(self)
      mappings.type(type_name, &block)
    end

    def to_hash
      main_hash = {}
      main_hash.update(mappings.to_hash) if mappings
      main_hash.update(settings.to_hash) if settings && settings.to_hash.any?
      { name => main_hash }
    end
  end
end
