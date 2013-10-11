require 'spec_helper'

describe 'install-server::caching-proxy', :type => :class do

    it { should contain_package('squid').with_ensure('latest') }
    it { should contain_service('squid').with_ensure('running') }

    it do
        should contain_file('/etc/squid/squid.conf').with({
            'ensure' => 'present',
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
        }).without_path()
    end

    it do
        should contain_file('/etc/logrotate.d/squid').with({
            'ensure' => 'present',
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
        }).without_path()
    end
end
