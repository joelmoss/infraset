require 'infraset/utilities'

module Infraset
  class ResourceFile
    include Infraset::Utilities
    attr_reader :path
    attr_reader :resources
    attr_reader :contents

    def initialize(file_path)
      @path = file_path
      @resources = []
      @contents = IO.read(path)
      @resource_count = 0

      evaluate_contents
    end

    def evaluate_contents
      instance_eval contents

      logger.debug "Found #{@resource_count} resource(s) in #{path}"
      resources.each { |res| logger.debug " - #{res}" }
    end

    def resource(namespace, type, name, &block)
      new_resource = Resource.new(namespace, type, name, path)
      new_resource.instance_eval &block
      @resource_count += 1
      resources << new_resource
    end

    def each
      resources.each { |r| yield r }
    end

  end
end
