module Infraset
  class Attribute
    ATTRIBUTE_TYPES = [ String, Array ]
    attr_accessor :name, :type, :options, :diff


    def initialize(name, type, options={})
      @name, @type = name, type
      @options = default_options.merge(options)
      @diff = nil

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
