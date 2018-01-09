require 'rspec-puppet'
require 'rspec-puppet-facts'

include RspecPuppetFacts
fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.module_path = File.expand_path("../..", File.dirname(__FILE__))
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.template_dir = File.join(fixture_path, 'templates')
  c.hiera_config = File.join(fixture_path, 'hiera.yaml')
end
