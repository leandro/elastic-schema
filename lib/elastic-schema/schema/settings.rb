module ElasticSchema::Schema
  class Settings
    attr_accessor :analysis

    def initialize(opts = {})
      opts = opts.inject({}) { |_opts, (key, value)| _opts(key.to_s => value) }

      %w(analysis).each do |attr|
        send(:"#{attr}=", opts[attr]) if opts.has_key?(attr)
      end
    end

    def to_hash
      main_hash = {}
      main_hash.update("analysis" => Analysis.analysis_for(analysis)) if analysis
      { "settings" => { "index" => main_hash } }
    end
  end
end
