require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'

include RspecPuppetFacts

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.hiera_config = File.join(fixture_path, 'hiera.yaml')
  test_on = { supported_os: [{'operatingsystem' => 'Debian', 'operatingsystemrelease' => ['8']}]}
  on_supported_os(test_on).each do |_, facts|
    facts[:initsystem] = 'systemd'
    c.default_facts = facts
  end
end
