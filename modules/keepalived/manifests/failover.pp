# SPDX-License-Identifier: Apache-2.0
# @summary Simple VIP failover setup with Keepalived
# @param auth_pass Authentication password to use between peers
# @param default_state Default state of the host (MASTER|BACKUP)
# @param interface Network interface to run the virtual address on
# @param peers List of peers
# @param priority VRRP priority of this host
# @param virtual_router_id VRRP virtual router id this host belongs to
# @param vips List of virtual IP address managed by keepalived (IP address/CIDR)
class keepalived::failover (
  Array[Stdlib::Fqdn]        $peers,
  String                     $auth_pass,
  Array[Stdlib::IP::Address] $vips,
  Enum['BACKUP', 'MASTER']   $default_state     = 'BACKUP',
  String                     $interface         = $::facts['networking']['primary'],
  Integer                    $priority          = fqdn_rand(100),
  Integer                    $virtual_router_id = 51,
) {
  $vips_v4 = $vips.filter |$vip| { $vip =~ Stdlib::IP::Address::V4 }
  $vips_v6 = $vips.filter |$vip| { $vip =~ Stdlib::IP::Address::V6 }

  $peer_ips = $peers.map |$peer| { dnsquery::lookup($peer, true) }.flatten
  $peers_v4 = $peer_ips.filter |$peer| { $peer =~ Stdlib::IP::Address::V4 }
  $peers_v6 = $peer_ips.filter |$peer| { $peer =~ Stdlib::IP::Address::V6 }

  if $vips_v6 {
    $source_v6 = $facts['networking']['ip6']
  } else {
    $source_v6 = undef
  }

  class { 'keepalived':
    config => template('keepalived/keepalived.conf.erb'),
  }
}
