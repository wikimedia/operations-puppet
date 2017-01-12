source 'https://rubygems.org'

gem 'puppet', ENV['PUPPET_GEM_VERSION'] || '~> 3.8.5'
gem 'xmlrpc' if RUBY_VERSION >= '2.4.0'
gem 'puppet-strings', '~> 1.0.0'
gem 'rspec-puppet', '~> 2.5.0'
gem 'rspec_junit_formatter', '~> 0.3.0'
gem 'puppetlabs_spec_helper', '< 2.0.0'
# Puppet 3.7 fails on ruby 2.2+
# https://tickets.puppetlabs.com/browse/PUP-3796
gem 'safe_yaml', '~> 1.0.4'

gem 'rake', '~> 12.0.0'
gem 'git', '1.3.0'
gem 'puppet-lint', '2.0.2'
gem 'rubocop', '~> 0.49.1', require: false
