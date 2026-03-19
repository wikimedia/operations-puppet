# SPDX-License-Identifier: Apache-2.0
#
# @summary Install and configure Bird
#   Configure Ferm
#   Configure anycast_healthchecker
# @param bfd if true enable bfd
# @param neighbors_list list of bgp neighbours
# @param bind_anycast_services The service names that bind to the anycast service e.g. gdnsd
# @param advertise_vips A hash of advertised virtual IPs
# @param multihop if true configure multihop
# @param anycasthc_logging logging configuration
# @param do_prom_exporter whether to enable the built-in Prometheus metrics
# @param prom_exporter_path if the above is enabled, path for directory where metrics are exported
# @param prom_exporter_interval the scraping period for the metrics
# @param supplementary_groups the additional supplementary group for the anycast-hc process
class profile::bird::anycast(
  Boolean                                        $bfd                    = lookup('profile::bird::bfd', {'default_value' => true}),
  Optional[Array[Stdlib::IP::Address::Nosubnet]] $neighbors_list         = lookup('profile::bird::neighbors_list', {default_value => undef}),
  Optional[Array[String[1], 1]]                  $bind_anycast_services  = lookup('profile::bird::bind_anycast_services', {'default_value' => undef}),
  Optional[Hash[String, Wmflib::Advertise_vip]]  $advertise_vips         = lookup('profile::bird::advertise_vips', {'default_value' => {}, 'merge' => hash}),
  Optional[Boolean]                              $multihop               = lookup('profile::bird::multihop', {'default_value' => true}),
  Optional[Bird::Anycasthc_logging]              $anycasthc_logging      = lookup('profile::bird::anycasthc_logging', {'default_value' => undef}),
  Optional[Stdlib::IP::Address::V4::Nosubnet]    $ipv4_src               = lookup('profile::bird::ipv4_src', {'default_value' => undef}),
  Optional[Stdlib::IP::Address::V6::Nosubnet]    $ipv6_src               = lookup('profile::bird::ipv6_src', {'default_value' => undef}),
  Optional[Boolean]                              $do_prom_exporter       = lookup('profile::bird::anycast::do_prom_exporter', {'default_value' => false}),
  Optional[Stdlib::Unixpath]                     $prom_exporter_path     = lookup('profile::bird::anycast::prom_exporter_path', {'default_value' => undef}),
  Optional[Integer[30]]                          $prom_exporter_interval = lookup('profile::bird::anycast::prom_exporter_interval', {'default_value' => undef}),
  Optional[Array[String[1], 1]]                  $supplementary_groups   = lookup('profile::bird::anycast::supplementary_groups', {'default_value' => undef}),
){

  # If even one service in advertise_vips sets address_ipv6, this means that
  # IPv6 support is desired. If that's the case, automatically set it for all
  # configs in the later code, as a single IPv6 setup will require those
  # configs. This supersedes the manual do_ipv6 hiera lookup.
  #
  # What if address_ipv6 is set but not check_cmd_ipv6? We check for that in
  # bird::anycast_healthchecker_check so it should fail there.
  $do_ipv6 = $advertise_vips.any |$vip_fqdn, $vip_params| {
    'address_ipv6' in $vip_params
  }

  $advertise_vips.each |$vip_fqdn, $vip_params| {
    interface::ip { "lo-vip-${vip_fqdn}":
      ensure    => $vip_params['ensure'],
      address   => $vip_params['address'],
      interface => 'lo',
      options   => 'label lo:anycast',
      before    => Service['bird'],
    }
    if $vip_params['address_ipv6'] {
      interface::ip { "lo-vip-${vip_fqdn}-ipv6":
        ensure    => $vip_params['ensure'],
        address   => $vip_params['address_ipv6'],
        prefixlen => 128,
        interface => 'lo',
        options   => 'label lo:anycast',
        before    => Service['bird'],
      }
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
  }

  class { 'bird::anycast_healthchecker':
      bind_service           => $bind_anycast_services,
      do_ipv6                => $do_ipv6,
      logging                => $anycasthc_logging,
      do_prom_exporter       => $do_prom_exporter,
      prom_exporter_path     => $prom_exporter_path,
      prom_exporter_interval => $prom_exporter_interval,
      supplementary_groups   => $supplementary_groups,
  }

  nrpe::plugin { 'check_anycast_healthchecker':
      ensure  => absent,
      content => '',
  }

  class { 'bird':
      neighbors    => $neighbors_list,
      bind_service => 'anycast-healthchecker.service',
      bfd          => $bfd,
      do_ipv6      => $do_ipv6,
      multihop     => $multihop,
      ipv4_src     => $ipv4_src,
      ipv6_src     => $ipv6_src,
  }
}
