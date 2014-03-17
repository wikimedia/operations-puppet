require 'spec_helper'

describe 'install-server::caching-proxy', :type => :class do
    let(:facts) { { :lsbdistid => 'Ubuntu', :lsbdistrelease => '10.04' } }

    it 'should  have squid with Ubuntu < 12.04' do
        contain_package('squid').with_ensure('latest')
        contain_service('squid').with_ensure('running')

        should contain_file('/etc/squid/squid.conf').with({
            'ensure' => 'present',
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
        }).without_path()

        should contain_file('/etc/logrotate.d/squid').with({
            'ensure' => 'present',
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
        }).without_path()
    end
end

describe 'install-server::caching-proxy', :type => :class do
    let(:facts) { { :lsbdistid => 'Ubuntu', :lsbdistrelease => '12.04' } }

    it 'should  have squid with Ubuntu >= 12.04' do
        contain_package('squid3').with_ensure('latest')
        contain_service('squid3').with_ensure('running')

        should contain_file('/etc/squid3/squid.conf').with({
            'ensure' => 'present',
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
        }).without_path()

        should contain_file('/etc/logrotate.d/squid').with({
            'ensure' => 'present',
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
        }).without_path()
    end
end
