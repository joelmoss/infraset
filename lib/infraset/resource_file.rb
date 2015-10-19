require 'cleanroom'

require 'infraset/utilities'
require 'infraset/resource_loader'

module Infraset
  class ResourceFile
    include Cleanroom
    include Infraset::Utilities

    attr_reader :path
    attr_reader :resources

    def initialize(file_path)
      @path = file_path
      @resources = []
      @resource_count = 0

      evaluate_contents
    end

    def evaluate_contents
      evaluate_file path

      logger.debug "Found #{@resource_count} resource(s) in #{path}"
      resources.each { |res| logger.debug " - #{res}" }
    end

    def resource(namespace, type, name, &block)
      loader = ResourceLoader.new(namespace, type, name, path)
      loader.evaluate &block
      @resource_count += 1
      resources << loader.resource
    end
    expose :resource

    def each
      resources.each { |r| yield r }
    end

  end
end
