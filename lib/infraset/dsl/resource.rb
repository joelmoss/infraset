require 'infraset/utilities'

module Infraset
  class DSL
    class Resource
      include Utilities

      attr_reader :namespace, :type

      def initialize(namespace, type)
        @namespace, @type = namespace, type
        logger.info "Resource '#{namespace}:#{type}'"
      end

      def name(value)
        @name = value
      end

      def to_s
        "#{namespace}:#{type}"
      end
    end
  end
end
