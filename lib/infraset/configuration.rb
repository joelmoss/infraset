module Infraset
  class Configuration

    def user_agent
      "infraset/#{Infraset::VERSION} (#{RUBY_PLATFORM})"
    end

  end
end
