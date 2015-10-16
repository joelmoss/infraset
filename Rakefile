Dir[File.join(Dir.pwd, 'tasks', '**', '*.rb')].each { |f| require f }
Dir[File.join(Dir.pwd, 'tasks', '*.rake')].each { |f| load f }

require 'bundler/gem_tasks'

Distribution.configure do |config|
  config.package_name = 'infraset'
  config.version = Infraset::VERSION
  config.rb_version = '20150715-2.2.2'
  config.packaging_dir = File.expand_path 'packaging'
  config.native_extensions = [
    # 'hitimes-1.2.3'
  ]
end
