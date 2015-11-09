module Infraset
  class Configuration
    extend Mixlib::Config

    log_level :info
    execute true
    resource_path "./"
    state_file "infraset.json"

  end
end
