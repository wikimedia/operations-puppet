require 'spec_helper'

describe 'k8s::controller', :type => :class do
  let(:facts) { {:fqdn => 'host.example.net'} }

  context 'with systemd as init' do
    let(:facts) { {:initsystem => 'systemd'} }

    it 'should containt a systemd unit file with correct certificate path' do
      should contain_file('/lib/systemd/system/controller-manager.service')
                 .with({ 'ensure' => 'present' })
                 .with_content(%r{--service-account-private-key-file=/var/lib/kubernetes/ssl/server.key})
    end

  end

end
