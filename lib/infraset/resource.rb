require 'infraset/utilities'

module Infraset
  class Resource
    include Infraset::Utilities

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

    def to_s
      "#{@namespace}:#{@type}[#{@name}]"
    end

    def instance_eval(&block)
      resource_object = @resource_class_name.new
      resource_object.instance_eval(&block)
    end

  end
end