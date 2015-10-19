require 'infraset/resource'

module Infraset
  class Resources
    class Aws
      class Animal < Infraset::Resource

        expose :species, String

      end
    end
  end
end