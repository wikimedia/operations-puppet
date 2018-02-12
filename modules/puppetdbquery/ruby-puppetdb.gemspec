# -*- encoding: UTF-8

lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'puppetdb'

Gem::Specification.new do |s|
  s.name        = 'ruby-puppetdb'
  s.version     = PuppetDB::VERSION.join '.'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Erik Dalen']
  s.email       = ['erik.gustav.dalen@gmail.com']
  s.homepage    = 'https://github.com/dalen/puppet-puppetdbquery'
  s.summary     = 'Query functions for PuppetDB'
  s.description = 'A higher level query language for PuppetDB.'
  s.license     = 'Apache v2'

  s.files         = Dir.glob('{bin,lib}/**/*')
  s.test_files    = Dir.glob('{test,spec,features,examples}/**/*')
  s.executables   = Dir.glob('bin/**/*').map { |f| File.basename f }
  s.require_paths = ['lib']

  s.add_dependency 'json'
  s.add_dependency 'chronic'
  s.add_dependency 'puppet', '>= 3.0.0', '< 5.0.0'
  s.add_development_dependency 'rspec', '~> 3.5'
  s.add_development_dependency 'rspec-expectations', '~> 3.5'
  s.add_development_dependency 'rspec-puppet', '~> 2.4'
  s.add_development_dependency 'rake', '~> 11.2'
  s.add_development_dependency 'puppetlabs_spec_helper'
  s.add_development_dependency 'racc', '~> 1.4'
  s.add_development_dependency 'rexical', '~> 1.0'
  s.add_development_dependency 'puppet-blacksmith', '~> 3.0'
end
