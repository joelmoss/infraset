module Infraset
  class Configuration
    extend Mixlib::Config

    log_level :info
    resource_path "./"
    state_file "infraset.json"

  end
end
