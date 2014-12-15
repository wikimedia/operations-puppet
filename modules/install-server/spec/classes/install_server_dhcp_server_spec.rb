require 'spec_helper'

describe 'install-server::dhcp-server', :type => :class do
    let(:facts) { { :lsbdistid => 'Ubuntu', :lsbdistrelease => '12.04' } }

    it 'should have isc-dhcp-server with <=12.04' do
        should contain_package('isc-dhcp-server').with_ensure('latest')
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
