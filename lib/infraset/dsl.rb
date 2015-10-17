require 'infraset/utilities'
require 'infraset/dsl/resource'

module Infraset
  class DSL
    include Utilities

    def resource(namespace, type, &block)
      resource = Resource.new(namespace, type)
      resource.instance_eval(&block)
    end
  end
end
