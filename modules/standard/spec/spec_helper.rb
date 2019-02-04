require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
require_relative '../../../rake_modules/fix_service_provider'

include RspecPuppetFacts
ENV['PUPPET_NOAPP_MANAGEMENT'] = 'true'
private_repo = 'https://gerrit.wikimedia.org/r/labs/private'
fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))
private_modules_path = File.join(fixture_path, 'private')
default_module_facts_path = File.expand_path(File.join(
  File.dirname(__FILE__), 'default_module_facts.yml'
))
default_facts = {
  puppetversion: Puppet.version,
  facterversion: Facter.version,
}

if File.exist?(default_module_facts_path) && File.readable?(default_module_facts_path)
  default_facts.merge!(YAML.safe_load(File.read(default_module_facts_path)))
end

# considered abusing fixtures for this but it ultimately just does the following
# https://github.com/puppetlabs/puppetlabs_spec_helper/blob/master/lib/puppetlabs_spec_helper/tasks/fixtures.rb#L148
system('git', 'clone', private_repo, private_modules_path)

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
  c.formatter = :documentation
  c.setup_fixtures = false
  c.default_facts = default_facts
  c.module_path = [
    File.expand_path('../../../modules', File.dirname(__FILE__)),
    File.join(private_modules_path, 'modules')
  ].join(':')
  c.hiera_config = File.join(fixture_path, 'hiera.yaml')
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
