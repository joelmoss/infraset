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

  end
end