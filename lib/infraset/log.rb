require 'paint'

module Infraset
  module Log
    extend Infraset::Utilities

    class << self
      INDENT = " " * 5

      def info(msg)
        if block_given?
          $stdout.puts Paint[msg2str("===> #{msg}"), :bright]
          yield
        else
          $stdout.puts INDENT + Paint[msg2str(msg)]
        end
      end

      def debug(msg)
        $stdout.puts INDENT + Paint[msg] if config.debug
      end

      def warn(msg)
        $stdout.puts INDENT + Paint[msg, :yellow]
      end

      def error(msg)
        $stderr.puts INDENT + Paint[msg, :red]
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
