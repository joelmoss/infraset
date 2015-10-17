require 'mixlib/log'

require 'infraset/version'
require 'infraset/configuration'

module Infraset
  Mixlib::Log::Formatter.show_time = false

  class Log
    extend Mixlib::Log
  end
end
