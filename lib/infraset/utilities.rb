module Infraset
  module Utilities

    def logger
      Infraset::Log
    end

    def config
      Configuration
    end

    def user_agent
      "infraset/#{Infraset::VERSION} (#{RUBY_PLATFORM})"
    end

    def debug(program, message)
      logger.debug("\e[#{36}m#{program.rjust(12)}\e[0m") { message }
    end

    def info(program, message)
      logger.info("\e[#{36}m#{program.rjust(12)}\e[0m") { message }
    end

    def error(program, message)
      logger.error("\e[#{36}m#{program.rjust(12)}\e[0m") { message }
    end

  end
end