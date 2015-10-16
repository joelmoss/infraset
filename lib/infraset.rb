require 'logger'

require 'infraset/version'
require 'infraset/configuration'

module Infraset
  NAME = 'Infraset'

  def self.config
    @config ||= Configuration.new
  end

  def self.logger
    @logger ||= Logger.new(STDOUT).tap do |l|
      l.level = Logger::INFO
      l.progname = 'INFRASET'
    end
  end

end
