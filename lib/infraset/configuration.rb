module Infraset
  class Configuration
    extend Mixlib::Config

    debug false
    execute true
    resource_path "./"
    state_file "infraset.json"

  end
end
