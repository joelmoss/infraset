require 'infraset/resource'

module Infraset
  class Resources
    class Aws
      class Animal < Infraset::Resource

        expose_accessor :species

      end
    end
  end
end