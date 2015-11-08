require 'forwardable'
require 'cleanroom'

require 'infraset/utilities'

module Infraset
  class Resource
    extend Forwardable
    include Cleanroom
    include Infraset::Utilities

    NULL = Object.new.freeze
    ATTRIBUTE_TYPES = [ String, Array ]

    def_delegators :@loader, :namespace, :type

    def initialize(loader)
      @loader = loader
      @attributes = {}
    end


    class << self

      # Define and expose an attribute with the given 'name`, `type` and `options`.
      def attribute(name, type, options = {})
        name = name.to_sym
        unless ATTRIBUTE_TYPES.include? type
          raise TypeError, "Attribute type of '#{type}' is not supported"
        end

        attributes[name] = {
          type: type,
          options: options,
          value: nil
        }

        define_method name do |value=NULL|
          if value.equal?(NULL) # reader
            default = options[:default]
            if !self.class.attributes[name][:value] && default
              if default.is_a?(Symbol)
                return respond_to?(default, true) ? send(default) : default
              else
                return default
              end
            end
          else # writer
            validate_attribute_type name, self.class.attributes[name], value
            self.class.attributes[name][:value] = value
          end

          self.class.attributes[name][:value]
        end

        expose name
      end

      def attributes
        @attributes ||= from_superclass(:attributes, {}).dup
      end

    end

    # The name of the resource
    attribute :name, String, default: :default_name

    def to_s
      "#{namespace}:#{type}[#{name}]"
    end

    def execute
      raise NotImplementedError, "#execute is not implemented on #{namespace}:#{type}"
    end


    private

      # The default name is taken from the second argument of `resource` if the name attribute is
      # not set.
      def default_name
        @loader.name
      end

      def validate_attribute_type(attr_name, attr_object, value)
        unless value.is_a?(attr_object[:type])
          raise TypeError, "value of attribute '#{attr_name}' is not a #{attr_object[:type]}"
        end
      end
  end
end
