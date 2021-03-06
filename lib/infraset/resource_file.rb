require 'cleanroom'

require 'infraset/resource_loader'

module Infraset
  class ResourceFile
    include Cleanroom
    include Infraset::Utilities

    attr_reader :path, :resources


    def initialize(file_path)
      @path, @resources, @resource_count = file_path, [], 0
      evaluate_contents
    end

    def resource(provider, type, name, &block)
      loader = ResourceLoader.new(provider, type, name, path)
      loader.evaluate &block
      @resource_count += 1
      resources << loader.resource
    end
    expose :resource

    def each
      resources.each { |r| yield r }
    end


    private

      def evaluate_contents
        evaluate_file path

        logger.debug "Found #{@resource_count} resource(s) in #{path}:"
        resources.each { |res| logger.debug "  #{res}" }
      end

  end
end
