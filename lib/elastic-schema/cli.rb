require 'optparse'

module ElasticSchema

  class CLI

    COMMANDS = %w(update check create drop recreate)

    def self.commands
      COMMANDS
    end

    def initialize(argv)
      @argv = argv

      # Default options values
      @options = {
        root: Dir.pwd,
        host: '127.0.0.1:9200'
      }

      parse!
    end

    def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: eschema [options] #{self.class.commands.join('|')}"

        opts.separator ""
        opts.separator "Setting options:"

        opts.on("-a", "--analysis_file FILE",
                "define the analysis file to be used (overwritten by -d)") { |analysis_file| @options[:analysis_file] = analysis_file }

        opts.on("-d", "--schema_dir DIR",
                "set directory where schema and analysis files are") { |schema_dir| @options[:schema_dir] = schema_dir }

        opts.on("-f", "--schema_file FILE",
                "define one fingle schema file to be used (overwritten by -d)") { |schema_file| @options[:schema_file] = schema_file }

        opts.on("-h", "--host HOST",
                "set address:port to connect to Elasticsearch (default: #{@options[:host]})") { |host| @options[:host] = host }

        opts.on("-r", "--root PATH",
                "set app root directory (default: #{@options[:root]})") { |root| @options[:root] = root }

      end
    end

    # Parse the options.
    def parse!
      parser.parse! @argv
      @command   = @argv.shift
      @arguments = @argv
    end

    # Parse the current shell arguments and run the command.
    # Exits on error.
    def run!
      if self.class.commands.include?(@command)
        run_command
      elsif @command.nil?
        puts "Command required"
        puts @parser
        exit 1
      else
        abort "Unknown command: #{@command}. Available commands: #{self.class.commands.join(', ')}"
      end
    end

    def run_command
      Command.new(@options).run(@command)
    end
  end
end
