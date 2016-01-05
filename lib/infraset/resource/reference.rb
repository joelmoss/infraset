module Infraset
  class Resource
    class Reference
      attr_reader :name
      attr_accessor :attribute

      def initialize(name)
        @name = name
      end

      def method_missing(attr)
        @attribute = attr
        self
      end
    end
  end
end
