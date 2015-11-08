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

    option :resource_path,
      short: '-r PATH',
      long: '--resource-path PATH',
      description: 'The relative path where the resources reside'

    option :log_level,
      short: '-l LEVEL',
      long: '--log-level LEVEL',
      description: 'Set the log level (debug, info, warn, error, fatal)',
      in: ['debug', 'info', 'warn', 'error', 'fatal'],
      proc: Proc.new { |l| l.to_sym }

    def run
      setup

      run_context = RunContext.new

      compile_resources run_context
      execute_resources run_context
    end

    # Collect the resources at the `resource_path` by scanning for Ruby files at the top level, then
    # adding them to the `run_context`.
    def compile_resources(run_context)
      logger.info "===> Compiling resources from #{config[:resource_path]}"

      run_context.resource_collection = ResourceCollection.new
      Dir.glob(File.join(config[:resource_path], "*.rb")).each do |file|
        run_context.resource_collection << ResourceFile.new(file)
      end
    end

    def execute_resources(run_context)
      logger.info "===> Executing #{run_context.resource_collection.count} resources"
      run_context.resource_collection.execute
    end


    private

      def setup
        print_banner
        parse_options
        parse_config
        setup_logging
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
