require 'logger'

module Infraset
  class LogFormatter < Logger::Formatter
    include Infraset::Utilities

    # Prints a log message as '[time] severity: message' if Chef::Log::Formatter.show_time == true.
    # Otherwise, doesn't print the time.
    def call(severity, time, progname, msg)
      if severity == 'FATAL' && !msg.is_a?(::Exception)
        msg = RuntimeError.new(msg)
      end

      if msg.is_a?(String) && msg.start_with?('===> ')
        sprintf "%s\n", msg2str(msg)
      elsif msg.is_a?(Exception) || (msg.is_a?(String) && msg =~ /^[-~+]/)
        sprintf "   %s\n", msg2str(msg)
      else
        sprintf "     %s\n", msg2str(msg)
      end
    end

    # Converts some argument to a Logger.severity() call to a string.  Regular strings pass through like
    # normal, Exceptions get formatted as "message (class)\nbacktrace", and other random stuff gets
    # put through "object.inspect"
    def msg2str(msg)
      case msg
      when ::String
        msg
      when ::Exception
        out = "\e[#{31}m! #{msg.message} (#{msg.class})\e[0m"
        if config.log_level == :debug
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
