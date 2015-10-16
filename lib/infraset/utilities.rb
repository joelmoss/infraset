module Infraset
  module Utilities

    def logger
      Infraset.logger
    end

    def config
      Infraset.config
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