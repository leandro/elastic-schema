module ElasticSchema::Schema
  class Analysis
    @@filters   = {}
    @@analyzers = {}

    def initialize(&block)
      instance_eval(&block)
    end

    def name(name)
      @name = name.to_s
    end

    def filter(name, opts = {})
      set_name                       = @name || 'global'
      @@filters[set_name]          ||= {}
      @@filters[set_name][name.to_s] = stringfy_symbols(opts)
    end

    def analyzer(name, opts)
      set_name                         = @name || 'global'
      @@analyzers[set_name]          ||= {}
      @@analyzers[set_name][name.to_s] = stringfy_symbols(opts)
    end

    def self.analysis_for(name = nil)
      name          = name ? name.to_s : 'global'
      analysis_hash = {}

      analysis_hash.update("filter" => @@filters[name]) if @@filters.has_key?(name)
      analysis_hash.update("analyzer" => @@analyzers[name]) if @@analyzers.has_key?(name)
      analysis_hash
    end

    private

    def stringfy_symbols(hash)
      hash.inject({}) do |_hash, (key, value)|
        value = value.is_a?(Array) ? value.map { |item| item.to_s } : value.to_s
        _hash.update(key.to_s => value)
      end
    end
  end
end
