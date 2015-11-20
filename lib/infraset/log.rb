require 'paint'

module Infraset
  module Log
    extend Infraset::Utilities

    class << self
      INDENT = " " * 5

      def info(msg=nil)
        if block_given?
          $stdout.puts msg.nil? ? "\n" : Paint[msg2str("===> #{msg}"), :bright]
          yield
        else
          $stdout.puts INDENT + Paint[msg2str(msg)]
        end
      end

      def added(resource, &block)
        $stdout.puts Paint[msg2str("   + #{resource}"), :green]
        yield
      end

      def modified(resource, &block)
        $stdout.puts Paint[msg2str("   ~ #{resource}"), :yellow]
        yield
      end

      def removed(resource)
        $stdout.puts Paint[msg2str("   - #{resource}"), :red]
        yield if block_given?
      end

      def debug(msg)
        $stdout.puts "#{INDENT}#{msg}" if config.debug
      end

      def fatal(msg)
        $stderr.puts "\n   " + msg2str(msg)
        exit 1
      end


      private

        # Converts some argument to a Logger.severity() call to a string.  Regular strings pass through like
        # normal, Exceptions get formatted as "message (class)\nbacktrace", and other random stuff gets
        # put through "object.inspect"
        def msg2str(msg)
          case msg
          when ::String
            msg
          when ::Exception
            out = Paint["! #{msg.message} (#{msg.class})", :red]
            if config.debug
              out << "\n     " << (msg.backtrace || []).join("\n     ")
            else
              out
            end
          else
            msg.to_s
          end
        end
    end

  end
end
