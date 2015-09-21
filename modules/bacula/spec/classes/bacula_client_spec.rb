require 'spec_helper'

describe 'bacula::client', :type => :class do
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

    it { should contain_package('bacula-fd') }
    it { should contain_service('bacula-fd') }
    it { should contain_exec('concat-bacula-keypair') }
    it 'should generate valid content for /etc/bacula/bacula-fd.conf' do
        should contain_file('/etc/bacula/bacula-fd.conf').with({
            'ensure'  => 'present',
            'owner'   => 'root',
            'group'   => 'root',
            'mode'    => '0400',
        },) \
        .with_content(/Name = "testdirector"/) \
        .with_content(/Password = "testdirectorpass"/) \
        .with_content(/TLS Certificate = "\/var\/lib\/puppet\/ssl\/certs\/testhost.example.com.pem"/) \
        .with_content(/TLS Key = "\/var\/lib\/puppet\/ssl\/private_keys\/testhost.example.com.pem"/) \
        .with_content(/Name = "testhost.example.com-fd"/) \
        .with_content(/FDport = 2000/) \
        .with_content(/PKI Keypair = "\/var\/lib\/puppet\/ssl\/private_keys\/bacula-keypair-testhost.example.com.pem"/)
    end
end
