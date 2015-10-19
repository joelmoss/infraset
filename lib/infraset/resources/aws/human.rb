require 'infraset/utilities'

module Infraset
  class Resources
    class Aws
      class Human
        include Infraset::Utilities

        def age(number)
          @age = number
        end
      end
    end
  end
end