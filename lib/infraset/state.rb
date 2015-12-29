require 'infraset/resources'

module Infraset
  class State < Resources

    # Overrides `super` to allow conversion that is only needed for adding a resource to the state.
    # This is because the state is a representation of the current state, and is obtained from a
    # different source (usually JSON), so some sanitization of values is sometimes needed.
    def []=(uid, params_or_resource)
      add uid, params_or_resource, sanitize_attributes: true
    end

  end
end
