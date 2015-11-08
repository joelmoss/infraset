require 'logger'

module Infraset
  class LogFormatter < Logger::Formatter
    # Prints a log message as '[time] severity: message' if Chef::Log::Formatter.show_time == true.
    # Otherwise, doesn't print the time.
    def call(severity, time, progname, msg)
      if msg.is_a?(String) && msg.start_with?('===> ')
        sprintf "%s\n", msg2str(msg)
      elsif msg.is_a?(String) && msg.start_with?('- ')
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
        "\e[#{31}m#{msg.message} (#{msg.class})\e[0m"
      else
        msg.to_s
      end
    end
  end
end
