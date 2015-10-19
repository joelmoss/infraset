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

    def to_s
      "#{namespace}:#{type}[#{name}]"
    end
  end
end
