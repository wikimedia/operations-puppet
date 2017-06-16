require 'spec_helper'

describe 'bacula::storage', :type => :class do
    let(:node) { 'testhost.example.com' }
    let(:params) { {
        :director => 'testdirector',
        :sd_max_concur_jobs => '10',
        :sqlvariant => 'testsql',
        :sd_port => '9000',
        :directorpassword => 'testdirectorpass',
        }
    }

    it { should contain_package('bacula-sd-testsql') }
    it { should contain_service('bacula-sd') }
    it do
        should contain_file('/etc/bacula/sd-devices.d').with({
        'ensure'  => 'directory',
        'recurse' => 'true',
        'force'   => 'true',
        'purge'   => 'true',
        'mode'    => '0444',
        'owner'   => 'root',
        'group'   => 'bacula',
        })
    end
    it 'should generate valid content for /etc/bacula/bacula-sd.conf' do
        should contain_file('/etc/bacula/bacula-sd.conf').with({
            'ensure'  => 'present',
            'owner'   => 'root',
            'group'   => 'root',
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
