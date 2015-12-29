module Infraset
  class ResourceLoader
    include Infraset::Utilities

    attr_reader :namespace
    attr_reader :provider
    attr_reader :type
    attr_reader :name
    attr_reader :path


    def initialize(provider, type, name, path)
      @provider, @type, @name, @path = provider, type, name, path
      @namespace = path.match(/#{configuration[:resource_path]}\/(.+)\.rb/i)[1]
    end

    def evaluate(&block)
      @resource_object = require_resource(@provider, @type).new(self)
      @resource_object.evaluate &block if block_given?
      @resource_object.validate!
    end

    def resource
      @resource_object
    end

  end
end