require 'elasticsearch'
require 'utils/hash'

module ElasticSchema
  autoload :CLI,     'elastic-schema/cli'
  autoload :Command, 'elastic-schema/command'

  module Schema
    autoload :Definition, 'elastic-schema/schema/definition'
    autoload :Migration,  'elastic-schema/schema/migration'
    autoload :Field,      'elastic-schema/schema/field'
    autoload :FieldsSet,  'elastic-schema/schema/fields_set'
    autoload :Mappings,   'elastic-schema/schema/mappings'
    autoload :Type,       'elastic-schema/schema/type'
    autoload :Settings,   'elastic-schema/schema/settings'
    autoload :Analysis,   'elastic-schema/schema/analysis'
    autoload :Index,      'elastic-schema/schema/Index'
  end
end
