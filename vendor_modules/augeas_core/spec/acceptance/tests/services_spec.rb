require 'spec_helper_acceptance'

RSpec.context 'Augeas services file' do
  before(:all) do
    on agents, 'cp /etc/services /tmp/services.bak'
  end

  after(:all) do
    on agents, 'cat /tmp/services.bak > /etc/services && rm /tmp/services.bak'
  end

  agents.each do |agent|
    context "on #{agent}" do
      it 'adds an entry to the services file' do
        on(hosts, puppet_apply('--verbose'), stdin: <<MANIFEST)
augeas { 'add_services_entry':
  context => '/files/etc/services',
  incl    => '/etc/services',
  lens    => 'Services.lns',
  changes => [
    'ins service-name after service-name[last()]',
    'set service-name[last()] "Doom"',
    'set service-name[. = "Doom"]/port "666"',
    'set service-name[. = "Doom"]/protocol "udp"'
  ]
}
MANIFEST
        on hosts, "fgrep 'Doom 666/udp' /etc/services"
      end

      it 'changes the protocol to udp' do
        on(hosts, puppet_apply('--verbose'), stdin: <<MANIFEST)
augeas { 'change_service_protocol':
  context => '/files/etc/services',
  incl    => '/etc/services',
  lens    => 'Services.lns',
  changes => [
    'set service-name[. = "Doom"]/protocol "tcp"'
  ]
}
MANIFEST
        on hosts, "fgrep 'Doom 666/tcp' /etc/services"
      end

      it 'removes the services entry' do
        on(hosts, puppet_apply('--verbose'), stdin: <<MANIFEST)
augeas { 'del_service_entry':
  context => '/files/etc/services',
  incl    => '/etc/services',
  lens    => 'Services.lns',
  changes => [
    'rm service-name[. = "Doom"]'
  ]
}
MANIFEST
        on hosts, "fgrep 'Doom 666/tcp' /etc/services", acceptable_exit_codes: [1]
      end
    end
  end
end
