require 'infraset/utilities'
require 'infraset/dsl/resource'

module Infraset
  class DSL
    include Utilities

    attr_reader :resource_count
    attr_accessor :resources

    def initialize
      @resource_count = 0
      @resources = []
    end

    def resource(namespace, type, &block)
      @resource_count =+ 1
      resource = Resource.new(namespace, type)
      resource.instance_eval(&block)
      resources << resource
    end
  end
end
