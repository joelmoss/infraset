require 'infraset/resource'

module Infraset
  class Resources
    class Aws
      class Animal < Infraset::Resource

        def species(value)
          @species = value
        end
        expose :species

      end
    end
  end
end