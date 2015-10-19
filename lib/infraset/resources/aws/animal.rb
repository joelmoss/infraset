require 'infraset/utilities'

module Infraset
  class Resources
    class Aws
      class Animal
        include Infraset::Utilities

        def species(value)
          @species = value
        end
      end
    end
  end
end