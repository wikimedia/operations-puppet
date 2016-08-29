require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))
root_path = File.expand_path(File.join(__FILE__, '..', '..', '..', '..'))

RSpec.configure do |c|
  c.module_path = [
          File.join(fixture_path, 'modules'),
          File.join(root_path, 'modules'),
      ].join(':')
  # Do not add c.manifest_dir which would boot manifests/site.pp
  c.template_dir = File.join(root_path, 'templates')
  c.environmentpath = File.join(Dir.pwd, 'spec')
  c.hiera_config = File.join(fixture_path, 'hiera.yaml')
end
