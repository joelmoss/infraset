require 'forwardable'
require 'cleanroom'
require 'hashdiff'

require 'infraset/attribute'
require 'infraset/resource/reference'

module Infraset
  class Resource
    extend Forwardable
    include Cleanroom
    include Infraset::Utilities

    NULL = Object.new.freeze

    attr_accessor :name, :id

    class << self
      # Define and expose an attribute with the given 'name`, `type` and `options`.
      def attribute(name, type, options = {})
        name = name.to_sym
        attributes[name] = Attribute.new(name, type, options)
        @named_attribute = name.to_s if options[:default] == :name

        define_method name do |value=NULL|
          if value.equal?(NULL) # reader
            attributes[name].value
          else # writer
            if value.is_a?(Infraset::Resource::Reference) && value.attribute.nil?
              value.attribute = name
            end
            attributes[name].value = value
          end
        end

        define_method "#{name}=" do |value|
          attributes[name].value = value
        end

        expose name
      end

      def attributes
        @attributes ||= from_superclass(:attributes, {}.with_indifferent_access).dup
      end

      def named_attribute
        @named_attribute ||= from_superclass(:named_attribute, NULL).dup
      end
    end


    # Initializes a resource.
    #
    # name  - The name of the resource as a String.
    # prov  - A Hash defining the provider name, type and ID (if the resource exists).
    # attrs - The attributes of this resource as a Hash.
    def initialize(name, prov={}, attrs={}, sanitize_attributes:false)
      if name.is_a? ResourceLoader
        @provider, @type, @name, @id = name.provider, name.type, name.name, nil
        @path, @namespace = name.path, name.namespace
      else
        @provider, @type, @name, @id = prov[:name], prov[:type], name, prov[:id]
        @path, @namespace = nil, nil
      end

      # Duplicate each attribute to ensure they are unique to the instance.
      attributes.each { |key,val| attributes[key] = val.dup }

      # Take any named attribute and set its value from the resource name.
      attributes[named_attribute].value = @name unless named_attribute.equal?(NULL)

      # Update the attributes with the values from the `attrs` argument.
      attrs.each do |key,val|
        attributes[key].set_value val, sanitize_attributes: sanitize_attributes
      end
    end

    def refs(ref)
      Reference.new(ref)
    end
    expose :refs

    def references
      @references ||= []
    end

    def diff_against(res)
      diff = HashDiff.diff(attributes_hash, res.attributes_hash)

      # Check that any changes are uniquely different. For example a string that is `nil` and `""`.
      # For such cases, no diff should be produced, and they should be treated the same.
      diff.map do |type,name,old,new|
        if attributes[name].type == String && old.empty? && new.nil?
          nil
        else
          [type,name,old,new]
        end
      end.compact
    end

    def should_recreate_for?(attr_name)
      recreate = attributes[attr_name].options[:recreate_on_update]
      recreate = recreate.nil? ? false : recreate
    end

    def to_s
      uid
    end

    def execute!(action)
      if action == 'delete'
        send :"#{action}!"
      else
        send :"save_resource_after_#{action}", send(:"#{action}!")
      end
    end

    # Refresh the current resource by fetching the current resource from its provider.
    def refresh!
      raise NotImplementedError, "#refresh! is not implemented on #{@provider}:#{@type}"
    end

    def to_json(a)
      {
        name: name,
        dependencies: references,
        provider: {
          id: id,
          name: @provider,
          type: @type
        },
        attributes: attributes
      }.to_json
    end

    def save_resource_after_create(result)
      raise NotImplementedError, "#save_resource_after_creation is not implemented on #{@provider}:#{@type}"
    end

    def save_resource_after_recreate(result)
      raise NotImplementedError, "#save_resource_after_recreation is not implemented on #{@provider}:#{@type}"
    end

    def save_resource_after_update(result)
      raise NotImplementedError, "#save_resource_after_update is not implemented on #{@provider}:#{@type}"
    end

    def uid
      "#{@provider}:#{@type}[#{name}]"
    end

    def attributes
      @attributes ||= self.class.attributes.dup
    end

    def attributes_hash
      hash = {}
      attributes.each do |n,v|
        hash[n] = v.value
      end
      hash
    end

    def named_attribute
      @named_attribute ||= self.class.named_attribute.dup
    end

    # Validate this resource.
    def validate!
      attributes.each do |name, attr|
        begin
          attr.validate!
        rescue => e
          raise TypeError, "`#{self}' - #{e}"
        end
      end
    end


    private

      def defaults
        @defaults ||= begin
          defs = {}
          attributes.each do |name, opts|
            next if name == :name
            defs[name] = default_for(name)
          end
          defs
        end
      end

  end
end
