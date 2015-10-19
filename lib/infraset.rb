require 'mixlib/log'
require 'active_support/inflector'

require 'infraset/version'
require 'infraset/configuration'

module Infraset
  Mixlib::Log::Formatter.show_time = false

  class Log
    extend Mixlib::Log
  end
end
