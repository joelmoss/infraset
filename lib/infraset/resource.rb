require 'forwardable'
require 'cleanroom'

module Infraset
  class Resource
    extend Forwardable
    include Cleanroom
    include Infraset::Utilities

    NULL = Object.new.freeze
    ATTRIBUTE_TYPES = [ String, Array ]

    attr_accessor :attributes, :current_state, :planned_state
    def_delegators :@loader, :namespace, :provider, :type, :path

    class << self

      # Define and expose an attribute with the given 'name`, `type` and `options`.
      def attribute(name, type, options = {})
        name = name.to_sym
        unless ATTRIBUTE_TYPES.include? type
          raise TypeError, "Attribute type of '#{type}' is not supported"
        end

        attributes[name] = {
          type: type,
          options: options
        }

        define_method name do |value=NULL|
          if value.equal?(NULL) # reader
            default = options[:default]
            if !planned_state[:attributes][name]
              if default
                if default.is_a?(Symbol)
                  return respond_to?(default, true) ? send(default) : default
                else
                  return default
                end
              else
                return nil
              end
            end
          else # writer
            validate_attribute_type name, planned_state[:attributes][name]
            planned_state[:attributes][name] = value
          end

          planned_state[:attributes][name]
        end

        expose name
      end

      def attributes
        @attributes ||= from_superclass(:attributes, {}).dup
      end

    end

    # The name of the resource
    attribute :name, String, default: :default_name


    def initialize(loader)
      @loader = loader
      @current_state = {id: nil, attributes: {}}.with_indifferent_access
      @planned_state = {id: nil, attributes: {}}.with_indifferent_access
      @to_be_created = false
      @to_be_updated = false
      @to_be_deleted = false
    end

    def to_s
      uid
    end

    def execute!
      save_state execute
    end

    def execute
      raise NotImplementedError, "#execute is not implemented on #{provider}:#{type}"
    end

    def save_state
      raise NotImplementedError, "#save_state is not implemented on #{provider}:#{type}"
    end

    def uid
      "#{provider}:#{type}[#{name}]"
    end

    def attributes
      self.class.attributes
    end

    # Mark this resource to be created.
    def should_create!
      @to_be_created = true
    end

    # Mark this resource to be updated.
    def should_update!
      @to_be_updated = true
    end

    # Mark this resource to be deleted.
    def should_delete!
      @to_be_deleted = true
    end


    private

      # The default name is taken from the second argument of `resource` if the name attribute is
      # not set.
      def default_name
        @loader.name
      end

      def validate_attribute_type(name, value)
        attr_object = self.class.attributes[name]
        if value && !value.is_a?(attr_object[:type])
          raise TypeError, "value of attribute '#{name}' is not a #{attr_object[:type]}"
        end
      end

  end
end
