require 'infraset/utilities'

module Infraset
  class DSL
    class Resource
      include Utilities

      attr_reader :name

      def initialize(namespace, type)
        logger.debug "Resource '#{namespace}:#{type}'"
      end

      def name(value)
        @name = value
      end
    end
  end
end
