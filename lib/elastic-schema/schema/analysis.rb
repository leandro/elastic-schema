module ElasticSchema::Schema
  class Analysis
    @@filters   = {}
    @@analyzers = {}

    def initialize(&block)
      instance_eval(&block)
    end

    def filter(name, opts = {})
      @@filters[name.to_s] = stringfy_symbols(opts)
    end

    def analyzer(name, opts)
      @@analyzers[name.to_s] = stringfy_symbols(opts)
    end

    private

    def stringfy_symbols(hash)
      hash.inject({}) do |_hash, (key, value)|
        value = value.to_s if value.is_a?(Symbol)
        value = value.map { |item| item.is_a?(Symbol) ? item.to_s : item } if value.is_a?(Array)
        _hash.update(key.to_s => value)
      end
    end
  end
end
