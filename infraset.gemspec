# -*- encoding: utf-8 -*-
require File.expand_path('../lib/infraset/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'infraset'
  spec.version       = Infraset::VERSION
  spec.authors       = ['Joel Moss']
  spec.email         = ['joel@developwithstyle.com']
  spec.summary       = 'Infraset CLI.'
  spec.homepage      = 'https://github.com/joelmoss/infraset'
  spec.license       = 'MIT'

  spec.files         = Dir['{lib,bin}/**/*']
  spec.executables << 'infraset'
  spec.require_paths = ['lib']

  spec.add_dependency 'mixlib-cli'
  spec.add_dependency 'mixlib-config'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'hashdiff'
  spec.add_dependency 'paint'
  spec.add_dependency 'cleanroom', '~> 1.0'
  spec.add_dependency 'aws-sdk-core', '~> 2'

  spec.add_development_dependency 'bundler',   '~> 1.7'
  spec.add_development_dependency 'rake',      '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'aruba'
  spec.add_development_dependency 'octokit'
end
