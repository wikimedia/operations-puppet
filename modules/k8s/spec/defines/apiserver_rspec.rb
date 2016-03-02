require 'spec_helper'

describe 'k8s::apiserver', :type => :class do
  let(:facts) { {:fqdn => 'host.example.net'} }
  let(:params) { {
      :etcd_servers => 'https://etcd.example.net:2379',
      :master_host  => 'example.net',
      :users        => [],
  } }

  context 'with systemd as init' do
    let(:facts) { {:initsystem => 'systemd'} }

    it 'should containt a systemd unit file with correct certificate path' do
      should contain_file('/lib/systemd/system/kube-apiserver.service')
                 .with({ 'ensure' => 'present' })
                 .with_content(/--tls-private-key-file=\/var\/lib\/kubernetes\/ssl\/server.key/)
                 .with_content(/--tls-cert-file=\/var\/lib\/kubernetes\/ssl\/cert.pem/)
                 .with_content(/--service-account-key-file=\/var\/lib\/kubernetes\/ssl\/server.key/)

    end

  end

end
