
RSpec.configure do |c|
  c.mock_with :rspec
end

require_relative 'monkey_patch_early'
require 'rspec-puppet'
require 'puppetlabs_spec_helper/puppet_spec_helper'
require 'rspec-puppet-facts'
require_relative 'fix_service_provider'

include RspecPuppetFacts
ENV['PUPPET_NOAPP_MANAGEMENT'] = 'true'
fixture_path = File.join(__dir__, '..', 'spec', 'fixtures')
private_modules_path = File.join(fixture_path, 'private')
facts_path = File.join(__dir__, 'default_facts.yml')
default_facts = {
  puppetversion: Puppet.version,
  facterversion: Facter.version,
}
if File.exist?(facts_path) && File.readable?(facts_path)
  default_facts.merge!(YAML.safe_load(File.read(facts_path)))
end

RSpec.configure do |c|
  c.before(:each) do
    if ENV['PUPPET_DEBUG']
      Puppet::Util::Log.level = :debug
      Puppet::Util::Log.newdestination(:console)
      if ENV['PUPPET_DEBUG'] == 'trace'
        Puppet[:trace] = true
      end
    end
  end
  c.color = true
  c.setup_fixtures = false
  c.default_facts = default_facts
  c.module_path = [
    File.join(__dir__, '..', 'modules'),
    File.join(__dir__, '..', 'vendor_modules'),
    File.join(private_modules_path, 'modules')
  ].join(':')
  c.hiera_config = File.join(__dir__, 'hiera.yaml')
end
# create a monkey patch to disable app_management.
# while app_management is enabled the site keyword
# becomes reserved and cant be used for resource
# parameters. This breaks the spec tests as Cumin::Selector
# has a site parameter
# https://github.com/rodjek/rspec-puppet/pull/742
module RSpec::Puppet
  module Support
    def setup_puppet
      vardir = Dir.mktmpdir
      Puppet[:vardir] = vardir
      if Puppet::Util::Package.versioncmp(Puppet.version, '4.3.0') >= 0 && Puppet.version.to_i < 5
        Puppet[:app_management] = ENV.include?('PUPPET_NOAPP_MANAGEMENT') ? false : true
      end
      load_path = adapter.modulepath.map do |d|
        Dir["#{d}/*/lib"].entries
      end
      load_path.flatten.each do |lib|
        $LOAD_PATH << lib
      end
      vardir
    end
  end
end

RSpec.configure do |c|
  # version on bullseye, if not set will not find new enough facts to test bullseye
  # would be nice if we could set this dynamically, but rspec-puppet-facts does not allow it for now
  c.default_facter_version = '3.14.12'
end

# Helper class for on_supported_os
class WMFConfig
  def self.test_on(min = 10, max = 11)
    {
      supported_os: [
        'operatingsystem' => 'Debian',
        'operatingsystemrelease' => (min.to_i..max.to_i).step(1).to_a.map(&:to_s),
      ]
    }
  end
end
