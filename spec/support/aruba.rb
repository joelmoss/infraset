require 'infraset/cli'

require 'aruba/rspec'
require 'aruba/in_process'

Aruba.configure do |config|
  config.command_launcher = :in_process
  config.main_class = Infraset::CLI
end
