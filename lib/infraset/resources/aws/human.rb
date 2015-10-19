require 'infraset/resource'

module Infraset
  class Resources
    class Aws
      class Human < Infraset::Resource

        def age(number)
          @age = number
        end
        expose :age

      end
    end
  end
end