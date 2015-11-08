require 'mixlib/cli'
require 'mixlib/config'

require 'infraset'
require 'infraset/log_formatter'
require 'infraset/utilities'
require 'infraset/configuration'
require 'infraset/run_context'
require 'infraset/resource_file'
require 'infraset/resource_collection'
require 'infraset/dsl'

module Infraset
  class CLI
    include Mixlib::CLI
    include Utilities

    attr_accessor :run_context

    option :resource_path,
      short: '-r PATH',
      long: '--resource-path PATH',
      description: 'The relative path where the resources reside'

    option :state_file,
      short: '-s PATH',
      long: '--state-file FILE',
      description: 'The relative path to the state file'

    option :log_level,
      short: '-l LEVEL',
      long: '--log-level LEVEL',
      description: 'Set the log level (debug, info, warn, error, fatal)',
      in: ['debug', 'info', 'warn', 'error', 'fatal'],
      proc: Proc.new { |l| l.to_sym }

    def run
      setup

      fetch_state
      compile_resources
      execute_resources

      exit 0
    rescue => e
      logger.fatal e
      exit 1
    end

    # Fetches the current state if available in the state file. Otherwise, a new empty state file is
    # created.
    def fetch_state
      logger.info "===> Determining state from #{config[:state_file]}"

      run_context.state = {}
      state_file = File.expand_path(config[:state_file])

      if File.exist?(state_file)
        begin
          run_context.state = JSON.parse(IO.read(state_file))
        rescue => e
          raise e.class, "Unable to read/parse state file\n     #{e}"
        end
      else
        logger.info "State file does not exist at #{state_file}. Creating..."
        state_dir = File.dirname(state_file)
        if Dir.exist? state_dir
          File.open(state_file, "w+") { |f| f.write JSON.generate(run_context.state) }
        else
          raise "Cannot create state file in #{state_dir}. Does that directory exist?"
        end
      end
    end

    # Collect the resources at the `resource_path` by scanning for Ruby files at the top level, then
    # adding them to the `run_context`.
    def compile_resources
      logger.info "===> Compiling resources from #{config[:resource_path]}"

      run_context.resource_collection = ResourceCollection.new
      Dir.glob(File.join(config[:resource_path], "*.rb")).each do |file|
        run_context.resource_collection << ResourceFile.new(file)
      end
    end

    def execute_resources
      logger.info "===> Executing #{run_context.resource_collection.count} resources"
      run_context.resource_collection.execute
    end


    private

      def setup
        print_banner
        parse_options
        parse_config
        setup_logging

        @run_context = RunContext.new
      end

      def setup_logging
        logger.formatter = Infraset::LogFormatter.new
        logger.level = config[:log_level]
      end

      def parse_config
        config.merge! config
      end

      def print_banner
        if $stdout.tty?
          puts "\e[#{32}m"
          puts banner
          puts "\e[0m"
        end
      end

      def banner
%Q{   _        __                    _
  (_)_ __  / _|_ __ __ _ ___  ___| |_
  | | '_ \\| |_| '__/ _` / __|/ _ \\ __|
  | | | | |  _| | | (_| \\__ \\  __/ |_
  |_|_| |_|_| |_|  \\__,_|___/\___|\\__|  #{user_agent}
}
      end

  end
end
