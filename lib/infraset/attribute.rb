module Infraset
  class Attribute
    attr_accessor :name, :type

    def initialize(name, type, options={})
      @name, @type = name, type
      @options = {recreate_on_update: false}.merge(options)
    end

  end
end
