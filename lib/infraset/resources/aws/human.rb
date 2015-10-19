require 'infraset/resource'

module Infraset
  class Resources
    class Aws
      class Human < Infraset::Resource

        expose_accessor :age

      end
    end
  end
end