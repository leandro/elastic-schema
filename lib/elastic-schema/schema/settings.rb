module ElasticSchema::Schema
  class Settings
    attr_accessor :analysis
    attr_reader   :index

    def initialize(index, opts = {})
      @index = index
      opts.deep_stringify_keys!

      %w(analysis).each do |attr|
        send(:"#{attr}=", opts[attr]) if opts.has_key?(attr)
      end
    end

    def to_hash
      main_hash = {}

      if analysis && (analysis_hash = Analysis.analysis_for(analysis)).any?
        main_hash.update("analysis" => analysis_hash)
      end

      main_hash.any? ? { "settings" => { "index" => main_hash } } : {}
    end
  end
end
