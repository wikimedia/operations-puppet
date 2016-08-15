require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.environmentpath = File.join(Dir.pwd, 'spec')
  c.hiera_config = File.join(fixture_path, 'hiera.yaml')
end
