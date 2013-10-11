require 'spec_helper'

describe 'install-server::web-server', :type => :class do

    it { should contain_package('lighttpd').with_ensure('latest') }
    it { should contain_service('lighttpd').with_ensure('running') }

    it do
        should contain_file('/etc/lighttpd/lighttpd.conf').with({
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
        })
    end
    it do
        should contain_file('/etc/logrotate.d/lighttpd').with({
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
        })
    end
end
