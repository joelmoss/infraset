require 'infraset/resource'

module Infraset
  class Resources
    class Aws
      class Route53Zone < Infraset::Resource

        attribute :comment, String

      end
    end
  end
end