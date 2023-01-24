require 'spec_helper_acceptance'

RSpec.context 'Augeas puppet configuration' do
  before(:all) do
    agents.each do |agent|
      on agent, "mv #{agent.puppet['confdir']}/puppet.conf /tmp/puppet.conf.bak"
    end
  end

  after(:all) do
    agents.each do |agent|
      on agent, "cat /tmp/puppet.conf.bak > #{agent.puppet['confdir']}/puppet.conf && rm /tmp/puppet.conf.bak"
    end
  end

  agents.each do |agent|
    context "on #{agent}" do
      it 'creates a new puppet config that has a master and agent section' do
        puppet_conf = <<CONF
[main]
CONF
        on agent, "echo \"#{puppet_conf}\" >> #{agent.puppet['confdir']}/puppet.conf"
      end

      it 'modifies an existing puppet config' do
        on(agent, puppet_apply('--verbose'), stdin: <<MANIFEST)
augeas { 'puppet agent noop mode':
  context => "/files#{agent.puppet['confdir']}/puppet.conf/agent",
  incl    => "/etc/puppetlabs/puppet/puppet.conf",
  lens    => 'Puppet.lns',
  changes => 'set noop true',
}
MANIFEST

        on agent, "grep 'noop=true' #{agent.puppet['confdir']}/puppet.conf"
      end
    end
  end
end
