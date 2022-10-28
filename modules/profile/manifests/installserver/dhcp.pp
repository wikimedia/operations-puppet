# SPDX-License-Identifier: Apache-2.0
# Installs a DHCP server and configures it for WMF
class profile::installserver::dhcp(
  Enum['stopped', 'running'] $ensure_service = lookup('profile::installserver::dhcp::ensure_service'),
){

  include network::constants
  class { 'install_server::dhcp_server':
    ensure_service => $ensure_service,
    mgmt_networks  => $network::constants::mgmt_networks_bydc,
  }

  ferm::service { 'dhcp':
    proto  => 'udp',
    port   => 'bootps',
    srange => '($PRODUCTION_NETWORKS $NETWORK_INFRA)',
  }
}
