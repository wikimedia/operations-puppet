# SPDX-License-Identifier: Apache-2.0
# == Class: profile::bird::anycast
#
# Install and configure Bird
# Configure Ferm
# Configure anycast_healthchecker
#

class profile::bird::anycast(
  Boolean                                        $bfd                  = lookup('profile::bird::bfd', {'default_value' => true}),
  Optional[Array[Stdlib::IP::Address::Nosubnet]] $neighbors_list       = lookup('profile::bird::neighbors_list', {default_value => undef}),
  Optional[String]                               $bind_anycast_service = lookup('profile::bird::bind_anycast_service', {'default_value' => undef}),
  Optional[Hash[String, Wmflib::Advertise_vip]]  $advertise_vips       = lookup('profile::bird::advertise_vips', {'default_value' => {}}),
  Optional[Boolean]                              $do_ipv6              = lookup('profile::bird::do_ipv6', {'default_value' => false}),
  Optional[Boolean]                              $multihop             = lookup('profile::bird::multihop', {'default_value' => true}),
  Optional[Bird::Anycasthc_logging]              $anycasthc_logging    = lookup('profile::bird::anycasthc_logging', {'default_value' => undef}),
){

  $advertise_vips.each |$vip_fqdn, $vip_params| {
    if $do_ipv6 and !$vip_params['address_ipv6'] {
      fail("IPv6 support was enabled but the IPv6 address for ${vip_fqdn} was not set.")
    }
  }

  if $neighbors_list {
    $_neighbors_list = $neighbors_list
    $_multihop = $multihop
  } else {
    $_neighbors_list = $do_ipv6 ? {
        true    => [$facts['default_routes']['ipv4'], $facts['default_routes']['ipv6']],
        default => [$facts['default_routes']['ipv4']],
    }
    $_multihop = false
  }

  $neighbors_for_ferm = join($_neighbors_list, ' ')

  ferm::service { 'bird-bgp':
      proto  => 'tcp',
      port   => '179',
      srange => "(${neighbors_for_ferm})",
      before => Class['::bird'],
  }

  # Ports from https://github.com/BIRD/bird/blob/master/proto/bfd/bfd.h#L28-L30
  if $bfd {
    ferm::service { 'bird-bfd-control':
        proto  => 'udp',
        port   => '3784',
        srange => "(${neighbors_for_ferm})",
        before => Class['::bird'],
    }
    ferm::service { 'bird-bfd-echo':
        proto  => 'udp',
        port   => '3785',
        srange => "(${neighbors_for_ferm})",
        before => Class['::bird'],
    }
    if $_multihop {
      ferm::service { 'bird-bfd-multi-ctl':  # Multihop BFD
          proto  => 'udp',
          port   => '4784',
          srange => "(${neighbors_for_ferm})",
          before => Class['::bird'],
      }
    }
  }

  class { '::bird::anycast_healthchecker':
      bind_service => $bind_anycast_service,
      do_ipv6      => $do_ipv6,
      logging      => $anycasthc_logging,
  }

  require ::profile::bird::anycast_healthchecker_monitoring

  class { '::bird':
      neighbors    => $_neighbors_list,
      bind_service => 'anycast-healthchecker.service',
      bfd          => $bfd,
      do_ipv6      => $do_ipv6,
      multihop     => $_multihop,
      require      => Class['::bird::anycast_healthchecker'],
  }

  $advertise_vips.each |$vip_fqdn, $vip_params| {
    interface::ip { "lo-vip-${vip_fqdn}":
      ensure    => $vip_params['ensure'],
      address   => $vip_params['address'],
      interface => 'lo',
      options   => 'label lo:anycast',
      before    => Class['::bird']
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
        before    => Class['::bird']
      }
    }
  }
  profile::contact { $title:
      contacts => ['ayounsi']
  }
}
