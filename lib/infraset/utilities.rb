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

    class << self
      def included(base) #:nodoc:
        base.extend ClassMethods
      end
    end


    module ClassMethods
      # Retrieves a value from superclass. If it reaches the `baseclass`, returns default.
      def from_superclass(method, default = nil)
        if self == baseclass || !superclass.respond_to?(method, true)
          default
        else
          value = superclass.send(method)

          # Ruby implements `dup` on Object, but raises a `TypeError` if the method is called on
          # immediates. As a result, we don't have a good way to check whether dup will succeed
          # without calling it and rescuing the TypeError.
          begin
            value.dup
          rescue TypeError
            value
          end
        end
      end

      # SIGNATURE: Sets the baseclass. This is where the superclass lookup
      # finishes.
      def baseclass #:nodoc:
      end
    end

  end
end