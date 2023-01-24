require 'spec_helper_acceptance'

RSpec.context 'Augeas hosts file' do
  before(:all) do
    on agents, 'cp /etc/hosts /tmp/hosts.bak'
  end

  after(:all) do
    on agents, 'cat /tmp/hosts.bak > /etc/hosts && rm /tmp/hosts.bak'
  end

  agents.each do |agent|
    context "on #{agent}" do
      it 'creates an entry in the hosts file' do
        on(agent, puppet_apply('--verbose'), stdin: <<MANIFEST)
augeas { 'add_hosts_entry':
  context => '/files/etc/hosts',
  incl    => '/etc/hosts',
  lens    => 'Hosts.lns',
  changes => [
    'set 01/ipaddr 192.168.0.1',
    'set 01/canonical pigiron.example.com',
    'set 01/alias[1] pigiron',
    'set 01/alias[2] piggy'
  ]
}
MANIFEST
        on agent, "fgrep '192.168.0.1\tpigiron.example.com pigiron piggy' /etc/hosts"
      end

      it 'modifies an entry in the hosts file' do
        on(hosts, puppet_apply('--verbose'), stdin: <<MANIFEST)
augeas { 'mod_hosts_entry':
  context => '/files/etc/hosts',
  incl    => '/etc/hosts',
  lens    => 'Hosts.lns',
  changes => [
    'set *[canonical = "pigiron.example.com"]/alias[last()+1] oinker'
  ]
}
MANIFEST
        on hosts, "fgrep '192.168.0.1\tpigiron.example.com pigiron piggy oinker' /etc/hosts"
      end

      it 'removes an entry from the hosts file' do
        on(hosts, puppet_apply('--verbose'), stdin: <<MANIFEST)
augeas { 'del_hosts_entry':
  context => '/files/etc/hosts',
  incl    => '/etc/hosts',
  lens    => 'Hosts.lns',
  changes => [
    'rm *[canonical = "pigiron.example.com"]'
  ]
}
MANIFEST
        on hosts, "fgrep 'pigiron.example.com' /etc/hosts", acceptable_exit_codes: [1]
      end
    end
  end
end
