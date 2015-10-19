require 'cleanroom'
require 'forwardable'

require 'infraset/utilities'

module Infraset
  class Resource
    extend Forwardable
    include Cleanroom
    include Infraset::Utilities

    def_delegators :@loader, :namespace, :type, :name

    def initialize(loader)
      @loader = loader
    end

    # Expose a method with the given `name` as a simple attribute writer
    def self.expose_accessor(name)
      define_method name do |*value|
        instance_variable_set :"@#{name}", value
      end
      expose name
    end

    def to_s
      "#{namespace}:#{type}[#{name}]"
    end
  end
end
