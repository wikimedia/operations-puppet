# SPDX-License-Identifier: Apache-2.0
#
# @summary Install and configure Bird
#   Configure Ferm
#   Configure anycast_healthchecker
# @param bfd if true enable bfd
# @param neighbors_list list of bgp neighbours
# @param bind_anycast_services The service names that bind to the anycast service e.g. gdnsd
# @param advertise_vips A hash of advertised virtual IPs
# @param do_ipv6 if true configure ipv6
# @param multihop if true configure multihop
# @param anycasthc_logging logging configuration
class profile::bird::anycast(
  Boolean                                        $bfd                   = lookup('profile::bird::bfd', {'default_value' => true}),
  Optional[Array[Stdlib::IP::Address::Nosubnet]] $neighbors_list        = lookup('profile::bird::neighbors_list', {default_value => undef}),
  Optional[Array[String[1], 1]]                  $bind_anycast_services = lookup('profile::bird::bind_anycast_services', {'default_value' => undef}),
  Optional[Hash[String, Wmflib::Advertise_vip]]  $advertise_vips        = lookup('profile::bird::advertise_vips', {'default_value' => {}, 'merge' => hash}),
  Optional[Boolean]                              $do_ipv6               = lookup('profile::bird::do_ipv6', {'default_value' => false}),
  Optional[Boolean]                              $multihop              = lookup('profile::bird::multihop', {'default_value' => true}),
  Optional[Bird::Anycasthc_logging]              $anycasthc_logging     = lookup('profile::bird::anycasthc_logging', {'default_value' => undef}),
  Optional[Stdlib::IP::Address::Nosubnet]        $ipv4_src              = lookup('profile::bird::ipv4_src', {'default_value' => undef}),
  Firewall::Provider                             $fw_provider           = lookup('profile::firewall::provider'),
){

  $advertise_vips.each |$vip_fqdn, $vip_params| {
    if $do_ipv6 and !$vip_params['address_ipv6'] {
      fail("IPv6 support was enabled but the IPv6 address for ${vip_fqdn} was not set.")
    }
  }

  $advertise_vips.each |$vip_fqdn, $vip_params| {
    interface::ip { "lo-vip-${vip_fqdn}":
      ensure    => $vip_params['ensure'],
      address   => $vip_params['address'],
      interface => 'lo',
      options   => 'label lo:anycast',
      before    => Service['bird'],
    }
    bird::anycast_healthchecker_check { "hc-vip-${vip_fqdn}":
      ensure         => $vip_params['ensure'],
      address        => $vip_params['address'],
      check_cmd      => $vip_params['check_cmd'],
      check_fail     => $vip_params['check_fail'],
      do_ipv6        => $do_ipv6,
      address_ipv6   => $vip_params['address_ipv6'],
      check_cmd_ipv6 => $vip_params['check_cmd_ipv6'],
    }
    if $do_ipv6 {
      interface::ip { "lo-vip-${vip_fqdn}-ipv6":
        ensure    => $vip_params['ensure'],
        address   => $vip_params['address_ipv6'],
        prefixlen => '128',
        interface => 'lo',
        options   => 'label lo:anycast',
        before    => Service['bird'],
      }
    }
  }

  class { 'bird::anycast_healthchecker':
      bind_service => $bind_anycast_services,
      do_ipv6      => $do_ipv6,
      logging      => $anycasthc_logging,
  }

  include profile::bird::anycast_healthchecker_monitoring

  class { 'bird':
      neighbors    => $neighbors_list,
      bind_service => 'anycast-healthchecker.service',
      bfd          => $bfd,
      do_ipv6      => $do_ipv6,
      multihop     => $multihop,
      ipv4_src     => $ipv4_src,
      fw_provider  => $fw_provider,
  }
}
