require_relative '../../../../rake_modules/spec_helper'

describe 'bacula::storage', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:node) { 'testhost.example.com' }
      let(:facts) { facts }
      let(:params) { {
        :director => 'testdirector',
        :sd_max_concur_jobs => '10',
        :sqlvariant => 'testsql',
        :sd_port => '9000',
        :directorpassword => 'testdirectorpass',
      }
      }

      context "when not stretch", if: facts[:os]['distro']['codename'] != 'stretch' do
        it { is_expected.to contain_package('bacula-sd') }
      end
      context "when stretch", if: facts[:os]['distro']['codename'] == 'stretch' do
        it { is_expected.to contain_package('bacula-sd-testsql') }
      end
      it { should contain_service('bacula-sd') }
      it do
        should contain_file('/etc/bacula/sd-devices.d').with({
          'ensure'  => 'directory',
          'recurse' => 'true',
          'force'   => 'true',
          'purge'   => 'true',
          'mode'    => '0550',
          'owner'   => 'bacula',
          'group'   => 'tape',
        })
      end
      it 'should generate valid content for /etc/bacula/bacula-sd.conf' do
        should contain_file('/etc/bacula/bacula-sd.conf').with({
          'ensure'  => 'present',
          'owner'   => 'bacula',
          'group'   => 'tape',
          'mode'    => '0400',
        }) \
          .with_content(/Name = "testdirector"/) \
          .with_content(/Password = "testdirectorpass"/) \
          .with_content(%r{TLS Certificate = "/etc/bacula/sd/ssl/cert.pem"}) \
          .with_content(%r{TLS Key = "/etc/bacula/sd/ssl/server.key"}) \
          .with_content(/Name = "testhost.example.com-fd"/) \
          .with_content(/SDport = 9000/) \
          .with_content(/Maximum Concurrent Jobs = 10/)
      end
    end
  end
end
