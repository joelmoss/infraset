module Infraset
  class Attribute
    ATTRIBUTE_TYPES = [ String, Array, Integer ]
    attr_accessor :name, :type, :options


    def initialize(name, type, options={})
      @name, @type = name, type
      @options = default_options.merge(options)

      unless ATTRIBUTE_TYPES.include? type
        raise TypeError, "Attribute type of '#{type}' is not supported"
      end
    end

    def value
      @value ||= default
    end

    def value=(val)
      if val && !val.is_a?(type)
        raise TypeError, "value of attribute '#{name}' is not a #{type}"
      end

      @value = val
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
