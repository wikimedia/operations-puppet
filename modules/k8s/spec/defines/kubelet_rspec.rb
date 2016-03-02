require 'spec_helper'

describe 'k8s::kubelet', :type => :class do
  let(:facts) { {:fqdn => 'host.example.net'} }
  let(:params) { {
      :master_host  => 'example.net',
  } }

  context 'with systemd as init' do
    let(:facts) { {:initsystem => 'systemd'} }

    it 'should containt a systemd unit file with correct certificate path' do
      should contain_file('/lib/systemd/system/kubelet.service')
                 .with({ 'ensure' => 'present' })
                 .with_content(%r{--tls-private-key-file=/var/lib/kubernetes/ssl/server.key})
                 .with_content(%r{--tls-cert-file=/var/lib/kubernetes/ssl/cert.pem})

    end

  end

end
