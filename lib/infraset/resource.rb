require 'forwardable'
require 'cleanroom'

require 'infraset/attribute'

module Infraset
  class Resource
    extend Forwardable
    include Cleanroom
    include Infraset::Utilities

    NULL = Object.new.freeze

    attr_accessor :namespace, :provider, :type, :path, :name, :id, :planned, :diff, :found_in_files

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
            attributes[name].value = value
          end
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
    def initialize(name, prov={}, attrs={})
      @to_be_created = false
      @to_be_recreated = false
      @to_be_updated = false
      @to_be_deleted = false
      @found_in_files = false

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
      attrs.each { |key,val| send key, val }

      validate!
    end

    def exist?
      !current_state[:id].nil?
    end

    def diff_against(res)
      HashDiff.diff attributes_hash, res.attributes_hash
    end

    def should_recreate_for?(attr_name)
      recreate = attributes[attr_name].options[:recreate_on_update]
      recreate = recreate.nil? ? false : recreate
    end

    def to_s
      uid
    end

    def print_attributes
      attributes.each { |k,v| logger.debug "#{k}: #{v.value}" }
    end

    def execute!
      if @to_be_created
        save_state_after_creation execute
      elsif @to_be_recreated
        save_state_after_recreation execute
      elsif @to_be_updated
        save_state_after_update execute
      elsif @to_be_deleted
        save_state_after_deletion execute
      end
    end

    def execute
      raise NotImplementedError, "#execute is not implemented on #{provider}:#{type}"
    end

    def save_state_after_creation
      raise NotImplementedError, "#save_state_after_creation is not implemented on #{provider}:#{type}"
    end

    def save_state_after_recreation
      raise NotImplementedError, "#save_state_after_recreation is not implemented on #{provider}:#{type}"
    end

    def save_state_after_update
      raise NotImplementedError, "#save_state_after_update is not implemented on #{provider}:#{type}"
    end

    def save_state_after_deletion
      raise NotImplementedError, "#save_state_after_deletion is not implemented on #{provider}:#{type}"
    end

    def uid
      "#{provider}:#{type}[#{name}]"
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

    %w( create recreate update delete ).each do |action|
      # Mark this resource to be `action`.
      define_method "should_#{action}!" do |new_res=nil|
        instance_variable_set :"@to_be_#{action}d", true
        planned = new_res if %w(recreate update).include? action
        self
      end

      # Should this resource be `action`d.
      define_method "should_#{action}?" do
        instance_variable_get :"@to_be_#{action}d"
      end
    end

    def planned_action
      if @to_be_created
        :create
      elsif @to_be_recreated
        :recreate
      elsif @to_be_updated
        :update
      elsif @to_be_deleted
        :delete
      else
        nil
      end
    end

    # Validate this resource. Right now this only validates any required attributes.
    def validate!
      attributes.each do |name, attr|
        if attr.options[:required] && planned_attributes[name].nil?
          raise "#{self} '#{name}' attribute is required"
        elsif attr.options[:required_if]
          req_if = attr.options[:required_if]
          if req_if.is_a?(Symbol) && (respond_to?(req_if, true) ? send(req_if) : req_if) && attributes[name].nil?
            raise "#{self} '#{name}' attribute is required"
          end
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
