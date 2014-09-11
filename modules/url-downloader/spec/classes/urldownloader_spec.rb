require 'spec_helper'

describe 'url-downloader', :type => :class do
    let(:node) { 'testhost.example.com' }
    let(:params) { {
        :service_ip => '10.10.10.10',
        }
    }

    context 'with ubuntu 10.04' do
        let(:facts) { { :lsbdistid => 'Ubuntu', :lsbdistrelease => '10.04' } }

        it { should contain_package('squid') }
        it { should contain_service('squid') }
        it { should contain_file('/etc/logrotate.d/squid') }
        it { should contain_file('/etc/squid/squid.conf').with_content(/10.10.10.10/) }
    end
    context 'with ubuntu 12.04' do
        let(:facts) { { :lsbdistid => 'Ubuntu', :lsbdistrelease => '12.04' } }

        it { should contain_package('squid3') }
        it { should contain_service('squid3') }
        it { should contain_file('/etc/logrotate.d/squid3') }
        it { should contain_file('/etc/squid3/squid.conf').with_content(/10.10.10.10/) }
    end
end
