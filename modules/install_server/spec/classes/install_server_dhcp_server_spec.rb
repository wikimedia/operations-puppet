require 'spec_helper'

describe 'install_server::dhcp_server', :type => :class do
    it 'should have isc-dhcp-server' do
        should contain_package('isc-dhcp-server').with_ensure('present')
        should contain_service('isc-dhcp-server').with_ensure('running')

        should contain_file('/etc/dhcp/').with({
            'ensure' => 'directory',
            'mode'   => '0444',
            'owner'  => 'root',
            'group'  => 'root',
            'recurse' => 'true',
        })
    end
end
