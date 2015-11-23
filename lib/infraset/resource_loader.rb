module Infraset
  class ResourceLoader
    include Infraset::Utilities

    attr_reader :namespace
    attr_reader :provider
    attr_reader :type
    attr_reader :name
    attr_reader :path


    def initialize(provider, type, name, path)
      @provider = provider
      @type = type
      @name = name
      @path = path
      @namespace = path.match(/#{config[:resource_path]}\/(.+)\.rb/i)[1]

      # Find the resource class
      resource_class_path = File.join('infraset', 'resources', @provider.to_s, "#{@type}")
      if File.exist?("lib/#{resource_class_path}.rb")
        require resource_class_path
        @resource_class_name = resource_class_path.camelize.constantize
      else
        raise LoadError, "cannot load such file -- #{resource_class_path}"
      end
    end

    def evaluate(&block)
      @resource_object = @resource_class_name.new(self)
      @resource_object.evaluate &block if block_given?
    end

    def resource
      @resource_object
    end

  end
end