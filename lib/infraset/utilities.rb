module Infraset
  module Utilities

    def logger
      Infraset::Log
    end

    def configuration
      Configuration
    end

    def user_agent
      "infraset/#{Infraset::VERSION} (#{RUBY_PLATFORM})"
    end

    # Find, require and return the resource class for the given provider and type.
    def require_resource(provider, type)
      resource_class_path = File.join('infraset', 'resources', provider.to_s, type.to_s)
      if File.exist?("lib/#{resource_class_path}.rb")
        require resource_class_path
        resource_class_path.camelize.constantize
      else
        raise LoadError, "cannot load such file -- #{resource_class_path}"
      end
    end

  end
end