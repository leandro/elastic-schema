require 'elasticsearch/transport'

module ElasticSchema

  autoload :CLI, 'elastic-schema/cli'
  autoload :Command, 'elastic-schema/command'

  module Schema
    autoload :Definition, 'elastic-schema/schema/definition'
  end

end
