$stdout.sync = true

require 'singleton'
require 'optparse'

require 'infraset'
require 'infraset/utilities'

module Infraset
  class CLI
    include Utilities
    include Singleton

    def parse!(args)
      OptionParser.new do |opts|
        opts.program_name = 'Infraset'
        opts.banner = "Usage: infraset [options]"
        opts.version = config.user_agent

        opts.on("-d", "--debug", "Set the level of logging (default: INFO)") do |debug|
          Infraset.logger.level = Logger::DEBUG if debug
        end
      end.parse! args
    end

    def run
      print_banner
    end

    private

      def print_banner
        if $stdout.tty?
          puts "\e[#{32}m"
          puts banner
          puts "\e[0m"
        end
      end

      def banner
%Q{    _        __                    _
    (_)_ __  / _|_ __ __ _ ___  ___| |_
    | | '_ \| |_| '__/ _` / __|/ _ \ __|
    | | | | |  _| | | (_| \__ \  __/ |_   Infraset
    |_|_| |_|_| |_|  \__,_|___/\___|\__|  #{config.user_agent}
}
      end

      def client
        @client ||= Infraset::Client.new
      end

  end
end
