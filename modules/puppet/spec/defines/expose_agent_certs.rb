require_relative '../../../../rake_modules/spec_helper'

describe 'puppet::expose_agent_certs', :type => :define do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:title) { '/my/ssl/dir' }
      let(:facts) { os_facts.merge(fqdn: 'host.example.net') }
      let(:pre_condition) { "class {'puppet::agent': ca_source => 'puppet:///modules/profile/puppet/ca.production.pem'}" }

      describe 'directory structure is created' do
        it { is_expected.to contain_file('/my/ssl/dir/ssl').with({ 'ensure' => 'directory', 'mode' => '0555' }) }
      end

      describe 'host certificate is exposed' do
        it { is_expected.to contain_file('/my/ssl/dir/ssl/cert.pem')
          .with({
          'ensure' => 'present',
          'mode' => '0444',
          'source' => '/var/lib/puppet/ssl/certs/host.example.net.pem',
        })
        }
      end

      describe 'private key is not exposed by default' do
        it { is_expected.to contain_file('/my/ssl/dir/ssl/server.key').with({ 'ensure' => 'absent' }) }
      end

      describe 'private key is exposed if required' do
        let(:params) { { provide_private: true } }

        it { is_expected.to contain_file('/my/ssl/dir/ssl/server.key')
          .with({
          'ensure' => 'present',
          'mode' => '0400',
          'source' => '/var/lib/puppet/ssl/private_keys/host.example.net.pem',
        })
        }
      end

      describe 'all files are removed when ensure => absent' do
        let(:params) { { ensure: 'absent' } }

        it { is_expected.to contain_file('/my/ssl/dir/ssl').with({ 'ensure' => 'absent' }) }
        it { is_expected.to contain_file('/my/ssl/dir/ssl/cert.pem').with({ 'ensure' => 'absent' }) }
        it { is_expected.to contain_file('/my/ssl/dir/ssl/server.key').with({ 'ensure' => 'absent' }) }
      end
    end
  end
end
