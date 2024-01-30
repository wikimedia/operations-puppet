require_relative '../../../../rake_modules/spec_helper'
require 'tempfile'

describe 'install_server::dhcp_server', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts){ facts }
      let(:params) {
        {
          http_server_ip: '10.0.0.1',
          datacenters_dhcp_config: {
            "eqiad" => {
              "tftp_server" => "208.80.154.74",
              "public" => {
                "subnets" => {
                  "public1-a-eqiad" => {
                    "ip" => "208.80.154.0",
                    "network_mask" => "255.255.255.192",
                    "broadcast_address" => "208.80.154.63",
                    "gateway_ip" => "208.80.154.1",
                  },
                  "public1-b-eqiad" => {
                    "ip" => "208.80.154.128",
                    "network_mask" => "255.255.255.192",
                    "broadcast_address" => "208.80.154.63",
                    "gateway_ip" => "208.80.154.1",
                  }
                },
                "domain" => "wikimedia.org"
              },
              "private" => {
                "subnets" => {
                  "private1-a-eqiad" => {
                    "ip" => "10.64.0.0",
                    "network_mask" => "255.255.252.0",
                    "broadcast_address" => "10.64.3.255",
                    "gateway_ip" => "10.64.0.1",
                  },
                  "private1-b-eqiad" => {
                    "ip" => "10.64.16.0",
                    "network_mask" => "255.255.252.0",
                    "broadcast_address" => "10.64.19.255",
                    "gateway_ip" => "10.64.16.1",
                  }
                },
                "domain" => "eqiad.wmnet"
              }
            },
            "codfw" => {
              "tftp_server" => "208.80.153.105",
              "public" => {
                "subnets" => {
                  "public1-a-codfw" => {
                    "ip" => "208.80.153.0",
                    "network_mask" => "255.255.255.224",
                    "broadcast_address" => "208.80.153.31",
                    "gateway_ip" => "208.80.153.1",
                  },
                  "public1-b-codfw" => {
                    "ip" => "208.80.153.32",
                    "network_mask" => "255.255.255.224",
                    "broadcast_address" => "208.80.153.63",
                    "gateway_ip" => "208.80.153.33",
                  }
                },
                "domain" => "wikimedia.org"
              },
              "private" => {
                "subnets" => {
                  "private1-a-codfw" => {
                    "ip" => "10.192.0.0",
                    "network_mask" => "255.255.252.0",
                    "broadcast_address" => "10.192.3.255",
                    "gateway_ip" => "10.192.0.1",
                  },
                  "private1-b-codfw" => {
                    "ip" => "10.192.16.0",
                    "network_mask" => "255.255.252.0",
                    "broadcast_address" => "10.192.19.255",
                    "gateway_ip" => "10.192.16.1",
                  }
                },
                "domain" => "codfw.wmnet"
              }
            }
          }
        }
      }
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
          .with_content(/
#
# codfw
#

group \{

    next-server 208.80.153.105;

    # Add DHCP option 12 \(hostname\) to the reply explicitly based on the host dhcp stanza title
    # Otherwise isc-dhcp relies on a DNS lookup on the IP
    use-host-decl-names on;

    # Public subnets
    group \{
        option domain-name "wikimedia.org";

        # public1-a-codfw subnet
        subnet 208.80.153.0 netmask 255.255.255.224 \{
            option broadcast-address 208.80.153.31;
            option subnet-mask 255.255.255.224;
            option routers 208.80.153.1;
        \}
        # public1-b-codfw subnet
        subnet 208.80.153.32 netmask 255.255.255.224 \{
            option broadcast-address 208.80.153.63;
            option subnet-mask 255.255.255.224;
            option routers 208.80.153.33;
        \}
    \}

    # Private subnets
    group \{
        option domain-name "codfw.wmnet";

        # private1-a-codfw subnet
        subnet 10.192.0.0 netmask 255.255.252.0 \{
            option broadcast-address 10.192.3.255;
            option subnet-mask 255.255.252.0;
            option routers 10.192.0.1;
        \}
        # private1-b-codfw subnet
        subnet 10.192.16.0 netmask 255.255.252.0 \{
            option broadcast-address 10.192.19.255;
            option subnet-mask 255.255.252.0;
            option routers 10.192.16.1;
        \}
    \}
\}/)
          .with_content(/
#
# eqiad
#

group \{

    next-server 208.80.154.74;

    # Add DHCP option 12 \(hostname\) to the reply explicitly based on the host dhcp stanza title
    # Otherwise isc-dhcp relies on a DNS lookup on the IP
    use-host-decl-names on;

    # Public subnets
    group \{
        option domain-name "wikimedia.org";

        # public1-a-eqiad subnet
        subnet 208.80.154.0 netmask 255.255.255.192 \{
            option broadcast-address 208.80.154.63;
            option subnet-mask 255.255.255.192;
            option routers 208.80.154.1;
        \}
        # public1-b-eqiad subnet
        subnet 208.80.154.128 netmask 255.255.255.192 \{
            option broadcast-address 208.80.154.63;
            option subnet-mask 255.255.255.192;
            option routers 208.80.154.1;
        \}
    \}

    # Private subnets
    group \{
        option domain-name "eqiad.wmnet";

        # private1-a-eqiad subnet
        subnet 10.64.0.0 netmask 255.255.252.0 \{
            option broadcast-address 10.64.3.255;
            option subnet-mask 255.255.252.0;
            option routers 10.64.0.1;
        \}
        # private1-b-eqiad subnet
        subnet 10.64.16.0 netmask 255.255.252.0 \{
            option broadcast-address 10.64.19.255;
            option subnet-mask 255.255.252.0;
            option routers 10.64.16.1;
        \}
    \}
\}/)

        # We now check that the generated DHCP config is valid, by shelling out to dhcpd
        dhcp_config = catalogue.resource('file', '/etc/dhcp/dhcpd.conf').send(:parameters)[:content]
        # We negate all includes to focus on the main dhcpd.conf file
        dhcp_config = dhcp_config.gsub('include', '# include')
        dhcp_config_file = Tempfile.new('dhcpd.conf')
        dhcp_config_file.write(dhcp_config)
        dhcp_config_file.flush
        dhcp_config_is_valid = system('/usr/sbin/dhcpd', '-t', '-cf', dhcp_config_file.path)
        expect(dhcp_config_is_valid).to eq true

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
