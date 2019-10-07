require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
require_relative '../../../rake_modules/fix_service_provider'

include RspecPuppetFacts
fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.hiera_config = File.join(fixture_path, 'hiera.yaml')
end
# Force usage of the systemd provider by overriding the stupid defaults
# set by puppetlabs. This is the same thing that the debian package does,
# please see https://salsa.debian.org/puppet-team/puppet/commit/428f6e560dea3cab2f0be39d51806c321bbf6e61
service_type = Puppet::Type.type(:service)
service_type.provider_hash[:systemd].defaultfor :operatingsystem => :debian
