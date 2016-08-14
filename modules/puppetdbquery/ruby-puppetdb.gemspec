# -*- encoding: UTF-8

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'puppetdb'

Gem::Specification.new do |s|
  s.name        = "ruby-puppetdb"
  s.version     = PuppetDB::VERSION.join '.'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Erik Dalen"]
  s.email       = ["erik.gustav.dalen@gmail.com"]
  s.homepage    = "https://github.com/dalen/puppet-puppetdbquery"
  s.summary     = %q{Query functions for PuppetDB}
  s.description = %q{A higher level query language for PuppetDB.}
  s.license     = 'Apache v2'


  s.files         = Dir.glob("{bin,lib}/**/*")
  s.test_files    = Dir.glob("{test,spec,features,examples}/**/*")
  s.executables   = Dir.glob("bin/**/*").map { |f| File.basename f }
  s.require_paths = ["lib"]

  s.add_dependency('json')
  s.add_dependency('chronic')
  s.add_development_dependency 'rspec', '2.13'
  s.add_development_dependency 'rspec-expectations'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'puppetlabs_spec_helper'
  s.add_development_dependency 'puppet'
  s.add_development_dependency 'racc', '~>1.4', '<1.4.12'
  s.add_development_dependency 'rexical'
  s.add_development_dependency 'puppet-blacksmith', '~>3.0'
  s.add_development_dependency 'mime-types', '< 2.0.0' if RUBY_VERSION < "1.9.0"
  s.add_development_dependency 'rest-client', '< 1.7.0' if RUBY_VERSION < "1.9.0"
end
