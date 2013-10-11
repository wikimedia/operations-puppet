require 'spec_helper'

describe 'install-server::dhcp-server', :type => :class do

    it { should contain_package('dhcp3-server').with_ensure('latest') }
    it { should contain_service('dhcp3-server').with_ensure('running') }

    it do
        should contain_file('/etc/dhcp3/').with({
            'ensure' => 'directory',
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
            'recurse' => 'true',
        })
    end
end
