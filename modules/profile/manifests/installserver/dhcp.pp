# SPDX-License-Identifier: Apache-2.0
# Installs a DHCP server and configures it for WMF
class profile::installserver::dhcp (
  Enum['stopped', 'running']               $ensure_service = lookup('profile::installserver::dhcp::ensure_service'),
  Hash[Wmflib::Sites, Stdlib::IP::Address] $tftp_servers   = lookup('profile::installserver::dhcp::tftp_servers'),
) {
  include network::constants

  $datacenters_dhcp_config = Hash(
    $network::constants::all_network_subnets['production'].map |$datacenter_name, $datacenter_config| {
      [
        $datacenter_name, {
          'tftp_server' => $tftp_servers[$datacenter_name],
          'public' => {
            'subnets' => profile::installserver::subnet_configs_by_audience($datacenter_config, 'public'),
            'domain' => 'wikimedia.org',
          },
          'private' => {
            'subnets' => profile::installserver::subnet_configs_by_audience($datacenter_config, 'private'),
            'domain' => "${datacenter_name}.wmnet",
          },
        }
      ]
    }
  )

  class { 'install_server::dhcp_server':
    ensure_service          => $ensure_service,
    mgmt_networks           => $network::constants::mgmt_networks_bydc,
    http_server_ip          => dnsquery::a('apt.discovery.wmnet') || { fail('unable to resolve') }[0],
    datacenters_dhcp_config => $datacenters_dhcp_config,
  }

  ferm::service { 'dhcp':
    proto  => 'udp',
    port   => 67,
    srange => '($PRODUCTION_NETWORKS $NETWORK_INFRA)',
  }
}
