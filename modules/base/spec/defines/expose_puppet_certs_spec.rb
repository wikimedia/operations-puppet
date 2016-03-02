require 'spec_helper'

describe 'base::expose_puppet_certs', :type => :define do

  describe 'directory structure is created' do
    let(:title) { '/my/ssl/dir' }

    it { should contain_file('/my/ssl/dir/ssl').with({ 'ensure' => 'directory', 'mode' => '0555' }) }
    it { should contain_file('/my/ssl/dir/ssl/certs').with({ 'ensure' => 'directory', 'mode' => '0555' }) }
    it { should contain_file('/my/ssl/dir/ssl/private_keys').with({ 'ensure' => 'directory', 'mode' => '0550' }) }
  end

  describe 'ca certificate is created' do
    let(:title) { '/my/ssl/dir' }

    it { should contain_file('/my/ssl/dir/ssl/certs/ca.pem').with({ 'ensure' => 'present', 'mode' => '0444'  }) }
  end

  describe 'host certificate is exposed' do
    let(:title) { '/my/ssl/dir' }
    let(:facts) { { :fqdn => 'host.example.net'} }

    it { should contain_file('/my/ssl/dir/ssl/certs/cert.pem')
                    .with({
                              'ensure' => 'present',
                              'mode' => '0400',
                              'source' => '/var/lib/puppet/ssl/certs/host.example.net.pem',
                          })
    }
  end

  describe 'private key is not exposed by default' do
    let(:title) { '/my/ssl/dir' }
    let(:facts) { { :fqdn => 'host.example.net'} }

    it { should_not contain_file('/my/ssl/dir/ssl/private_keys/server.key') }
  end

  describe 'private key is exposed if required' do
    let(:title) { '/my/ssl/dir' }
    let(:facts) { { :fqdn => 'host.example.net'} }
    let(:params) { { :provide_private => true } }

    it { should contain_file('/my/ssl/dir/ssl/private_keys/server.key')
                    .with({
                              'ensure' => 'present',
                              'mode' => '0400',
                              'source' => '/var/lib/puppet/ssl/private_keys/host.example.net.pem',
                          })
    }
  end

end
