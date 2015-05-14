require 'optparse'

module ElasticSchema

  class CLI

    COMMANDS = %w(update check create drop recreate)

    def self.commands
      COMMANDS
    end

    def initialize(options)
    end

    def run!
    end

  end

end
