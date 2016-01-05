module Infraset
  class Attribute
    ATTRIBUTE_TYPES = [ String, Array, Integer ]
    attr_accessor :name, :type, :options
    attr_reader :reference
    attr_writer :value


    def initialize(name, type, options={})
      @name, @type = name, type
      @options = default_options.merge(options)

      unless ATTRIBUTE_TYPES.include? type
        raise TypeError, "Attribute type of '#{type}' is not supported"
      end
    end

    # Validate this resource. Right now this validates any required attributes, and that strings are
    # not empty. Also validates the type of the attribute value.
    def validate!
      if options[:required] && blank?
        raise "'#{name}' attribute is required"
      elsif options[:required_if]
        req_if = options[:required_if]
        if req_if.is_a?(Symbol) && (respond_to?(req_if, true) ? send(req_if) : req_if) && blank?
          raise "'#{name}' attribute is required, because `required_if` is given (`#{req_if}`)"
        end
      end

      if !value.is_a?(type)
        raise "Value of attribute '#{name}' is not a #{type}"
      end
    end

    def reference?
      value.is_a?(Infraset::Resource::Reference)
    end

    def reference
      reference? && value
    end

    def value
      @value ||= default
    end

    def set_value(val, sanitize_attributes:false)
      self.value = sanitize_attributes && !val.is_a?(type) ? send(:"#{type}", val) : val
    end

    def to_s
      value.to_s
    end

    def blank?
      value.nil? || value.empty?
    end

    def empty?
      /\A[[:space:]]*\z/ === value
    end

    def nil?
      value.nil?
    end

    def to_json(*args)
      value.to_json
    end


    private

      def default_options
        { recreate_on_update: false }.with_indifferent_access
      end

      def default
        default ||= if _default = @options[:default]
          if _default.is_a?(Symbol)
            respond_to?(_default, true) ? send(_default) : _default
          else
            _default
          end
        else
          nil
        end
      end

  end
end
