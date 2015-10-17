require 'mixlib/cli'
require 'mixlib/config'

require 'infraset'
require 'infraset/utilities'
require 'infraset/configuration'
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
      show_plan
    end

    def show_plan
      files = File.join(config[:resource_path], "**", "*.rb")
      Dir.glob(files).each do |file|
        logger.debug "Evaluating #{file} for resources"
        contents = File.read(file)
        DSL.new.instance_eval contents
      end
    end


    private

      def setup
        print_banner
        parse_options
        parse_config
        setup_logging
      end

      def setup_logging
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
