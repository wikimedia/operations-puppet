require_relative '../../../../rake_modules/spec_helper'

describe 'bacula::client', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:node) { 'testhost.example.com' }
      let(:params) { {
        :director => 'testdirector',
        :catalog => 'testcatalog',
        :file_retention => 'testfr',
        :job_retention => 'testjr',
        :fdport => '2000',
        :directorpassword => 'testdirectorpass',
      }
      }
      let(:pre_condition) do
        "class {'base::puppet': ca_source => 'puppet:///files/puppet/ca.production.pem'}
        class profile::base ( $notifications_enabled = 1 ){}
        include profile::base
        "
      end

      it { should contain_package('bacula-fd') }
      it { should contain_service('bacula-fd') }
      it 'should generate valid content for /etc/bacula/bacula-fd.conf' do
        should contain_file('/etc/bacula/bacula-fd.conf').with({
          'ensure'  => 'present',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0400',
        }) \
          .with_content(/Name = "testdirector"/) \
          .with_content(/Password = "testdirectorpass"/) \
          .with_content(%r{TLS Certificate = "/etc/bacula/ssl/cert.pem"}) \
          .with_content(%r{TLS Key = "/etc/bacula/ssl/server.key"}) \
          .with_content(/Name = "testhost.example.com-fd"/) \
          .with_content(/FDport = 2000/) \
          .with_content(%r{PKI Keypair = "/etc/bacula/ssl/server-keypair.pem"})
      end
    end
  end
end
