require 'infraset/utilities'

module Infraset
  class ResourceLoader
    include Infraset::Utilities

    attr_reader :namespace
    attr_reader :type
    attr_reader :name
    attr_reader :path

    def initialize(namespace, type, name, path)
      @namespace = namespace
      @type = type
      @name = name
      @path = path

      # Find the resource class
      resource_class_path = File.join('infraset', 'resources', @namespace.to_s, "#{@type}")
      if File.exist?("lib/#{resource_class_path}.rb")
        require resource_class_path
        @resource_class_name = resource_class_path.camelize.constantize
      else
        raise LoadError, "cannot load such file -- #{resource_class_path}"
      end
    end

    def evaluate(&block)
      @resource_object = @resource_class_name.new(self)
      @resource_object.evaluate &block
    end

    def resource
      @resource_object
    end

  end
end