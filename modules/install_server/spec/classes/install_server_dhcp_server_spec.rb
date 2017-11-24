require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8'], # we cannot support stretch atm because of a bug in the service provider in
      # the puppet gem, that is fixed in debian itself...
    }
  ]
}

describe 'install_server::dhcp_server', :type => :class do
  on_supported_os(test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts){ facts }
      it { is_expected.to compile }

      it 'should have isc-dhcp-server' do
        is_expected.to contain_package('isc-dhcp-server').with_ensure('present')
        is_expected.to contain_service('isc-dhcp-server').with_ensure('running')

        is_expected.to contain_file('/etc/dhcp').with(
                 {
                   'ensure' => 'directory',
                   'mode'   => '0444',
                   'owner'  => 'root',
                   'group'  => 'root',
                   'recurse' => 'true',
                 }
               )
      end
    end
  end
end
