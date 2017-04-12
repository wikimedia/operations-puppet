require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
include RspecPuppetFacts


RSpec.configure do |c|
  c.include PuppetlabsSpec::Files

  c.before :each do
    # Store any environment variables away to be restored later
    @old_env = {}
    ENV.each_key {|k| @old_env[k] = ENV[k]}

    c.strict_variables = Gem::Version.new(Puppet.version) >= Gem::Version.new('3.5')
    Puppet.features.stubs(:root?).returns(true)
  end

  c.after :each do
    PuppetlabsSpec::Files.cleanup
  end
end

require 'pathname'
dir = Pathname.new(__FILE__).parent
Puppet[:modulepath] = File.join(dir, 'fixtures', 'modules')

# There's no real need to make this version dependent, but it helps find
# regressions in Puppet
#
# 1. Workaround for issue #16277 where default settings aren't initialised from
# a spec and so the libdir is never initialised (3.0.x)
# 2. Workaround for 2.7.20 that now only loads types for the current node
# environment (#13858) so Puppet[:modulepath] seems to get ignored
# 3. Workaround for 3.5 where context hasn't been configured yet,
# ticket https://tickets.puppetlabs.com/browse/MODULES-823
#
ver = Gem::Version.new(Puppet.version.split('-').first)
if Gem::Requirement.new("~> 2.7.20") =~ ver || Gem::Requirement.new("~> 3.0.0") =~ ver || Gem::Requirement.new("~> 3.5") =~ ver || Gem::Requirement.new("~> 4.0")
  puts "augeasproviders: setting Puppet[:libdir] to work around broken type autoloading"
  # libdir is only a single dir, so it can only workaround loading of one external module
  Puppet[:libdir] = "#{Puppet[:modulepath]}/augeasproviders_core/lib"
end
