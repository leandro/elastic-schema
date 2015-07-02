require 'elasticsearch'

module ElasticSchema

  autoload :CLI, 'elastic-schema/cli'
  autoload :Command, 'elastic-schema/command'

  module Schema
    autoload :Definition, 'elastic-schema/schema/definition'
    autoload :Migration, 'elastic-schema/schema/migration'
    autoload :Field, 'elastic-schema/schema/field'
    autoload :FieldsSet, 'elastic-schema/schema/fields_set'
    autoload :Mapping, 'elastic-schema/schema/mapping'
  end

end
