require_relative '../../../../rake_modules/spec_helper'

describe 'install_server::dhcp_server', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts){ facts }
      let(:params) {{ http_server_ip: '10.0.0.1' }}
      it { is_expected.to compile }

      it 'should have isc-dhcp-server' do
        is_expected.to contain_package('isc-dhcp-server').with_ensure('installed')
        is_expected.to contain_service('isc-dhcp-server').with_ensure('running')

        is_expected.to contain_file('/etc/dhcp').with(
          {
            'ensure' => 'directory',
            'mode'   => '0444',
          }
        )
        is_expected.to contain_file('/etc/dhcp/dhcpd.conf')
        is_expected.to contain_file('/etc/dhcp/automation.conf')
          .without_content(/subnet/)
      end
      describe 'with managment networks' do
        let(:params) { {
          mgmt_networks: {'eqiad' => ['10.0.0.0/22'], 'codfw' => ['10.0.4.0/23'] },
          http_server_ip: '10.0.0.1'
        } }
        it do
          is_expected.to contain_file('/etc/dhcp/automation.conf')
            .with_content(%r{
              subnet\s10.0.0.0\snetmask\s255.255.252.0\s\{\s+
                option\ssubnet-mask\s255.255.252.0;\s+
                option\srouters\s10.0.0.1;\s+
                option\sdomain-name\s"mgmt\.eqiad\.wmnet";\s+
                include\s"/etc/dhcp/automation/proxies/mgmt-eqiad.conf";\n\}
            }x)
            .with_content(%r{
              subnet\s10.0.4.0\snetmask\s255.255.254.0\s\{\s+
                option\ssubnet-mask\s255.255.254.0;\s+
                option\srouters\s10.0.4.1;\s+
                option\sdomain-name\s"mgmt\.codfw\.wmnet";\s+
                include\s"/etc/dhcp/automation/proxies/mgmt-codfw.conf";\n\}
            }x)
        end
      end
    end
  end
end
