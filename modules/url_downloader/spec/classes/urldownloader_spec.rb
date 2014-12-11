require 'spec_helper'

describe 'url_downloader', :type => :class do
    let(:node) { 'testhost.example.com' }
    let(:params) { {
        :service_ip => '10.10.10.10',
        }
    }

    it { should contain_package('squid3') }
    it { should contain_service('squid3') }
    it { should contain_file('/etc/logrotate.d/squid3') }
    it { should contain_file('/etc/squid3/squid.conf').
        with_content(/10.10.10.10/).
        with_content(/^acl (?! all src)/)
    }
end
