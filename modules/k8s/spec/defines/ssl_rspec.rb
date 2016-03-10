require 'spec_helper'

describe 'k8s::ssl', :type => :class do
  let(:facts) { { :fqdn => 'host.example.net'} }

  describe 'certificates are exposed' do
    it { should contain_file('/var/lib/kubernetes/ssl').with({ 'ensure' => 'directory' }) }
    it { should contain_file('/var/lib/kubernetes/ssl/cert.pem').with({ 'ensure' => 'present' }) }
  end

  describe 'private key is not exposed by default' do
    it { should_not contain_file('/var/lib/kubernetes/ssl/private_keys/server.key') }
  end

  describe 'private key is exposed if required' do
    let(:params) { { :provide_private => true } }

    it { should contain_file('/var/lib/kubernetes/ssl/server.key')
                    .with({
                              'ensure' => 'present',
                              'mode' => '0400',
                              'source' => '/var/lib/puppet/ssl/private_keys/host.example.net.pem',
                          })
    }
  end

end
