require 'spec_helper'

describe 'base::expose_puppet_certs', :type => :define do
  let(:title) { '/my/ssl/dir' }
  let(:facts) { { :fqdn => 'host.example.net'} }

  describe 'directory structure is created' do
    it { should contain_file('/my/ssl/dir/ssl').with({ 'ensure' => 'directory', 'mode' => '0555' }) }
  end

  describe 'host certificate is exposed' do
    it { should contain_file('/my/ssl/dir/ssl/cert.pem')
                    .with({
                              'ensure' => 'present',
                              'mode' => '0444',
                              'source' => '/var/lib/puppet/ssl/certs/host.example.net.pem',
                          })
    }
  end

  describe 'private key is not exposed by default' do
    it { should contain_file('/my/ssl/dir/ssl/server.key').with({ 'ensure' => 'absent' }) }
  end

  describe 'private key is exposed if required' do
    let(:params) { { :provide_private => true } }

    it { should contain_file('/my/ssl/dir/ssl/server.key')
                    .with({
                              'ensure' => 'present',
                              'mode' => '0400',
                              'source' => '/var/lib/puppet/ssl/private_keys/host.example.net.pem',
                          })
    }
  end

  describe 'all files are removed when ensure => absent' do
    let(:params) { { :ensure => 'absent' } }

    it { should contain_file('/my/ssl/dir/ssl/').with({ 'ensure' => 'absent' }) }
    it { should contain_file('/my/ssl/dir/ssl/cert.pem').with({ 'ensure' => 'absent' }) }
    it { should contain_file('/my/ssl/dir/ssl/server.key').with({ 'ensure' => 'absent' }) }
  end

end

# adding a test on the exposition of Puppet CA cert here to make it explicit
# that clients of base::expose_puppet_certs most probably need this cert to be
# exposed as well
describe 'base::certificates', :type => :class do
  describe 'exposes Puppet CA certificate' do
    it { should contain_file('/usr/local/share/ca-certificates/Puppet_Internal_CA.crt').with({ 'ensure' => 'present' }) }
  end
end
