# == Class: profile::bird::anycast
#
# Install and configure Bird
# Configure Ferm
# Configure anycast_healthchecker
#

class profile::bird::anycast(
  Boolean $bfd = lookup('profile::bird::bfd', {'default_value' => true}),
  Optional[Array[Stdlib::IP::Address::V4::Nosubnet]] $neighbors_list = lookup('profile::bird::neighbors_list', {'default_value' => []}),
  Optional[String] $bind_anycast_service = lookup('profile::bird::bind_anycast_service', {'default_value' => undef}),
  Optional[Hash[String, Wmflib::Advertise_vip]] $advertise_vips = lookup('profile::bird::advertise_vips', {'default_value' => {}}),
  Optional[Array[Stdlib::Fqdn]] $prometheus_nodes = hiera('prometheus_nodes', undef),
){
  if $neighbors_list {
    $neighbors_for_ferm = join($neighbors_list, ' ')
    ferm::service { 'bird-bgp':
        proto  => 'tcp',
        port   => '179',
        srange => "(${neighbors_for_ferm})",
        before => Class['::bird'],
    }
  }
  # Ports from https://github.com/BIRD/bird/blob/master/proto/bfd/bfd.h#L28-L30
  if $neighbors_list and $bfd {
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
    ferm::service { 'bird-bfd-multi-ctl':  # Multihop BFD
        proto  => 'udp',
        port   => '4784',
        srange => "(${neighbors_for_ferm})",
        before => Class['::bird'],
    }
  }

  if $prometheus_nodes {
      $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
      ferm::service { 'bird-prometheus-acl':
          desc   => 'Bird prometheus port',
          proto  => 'tcp',
          port   => '9324',
          srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
      }
  }

  class { '::bird::anycast_healthchecker':
      bind_service => $bind_anycast_service,
  }

  require ::profile::bird::anycast_healthchecker_monitoring

  class { '::bird':
      config_template => 'bird/bird_anycast.conf.erb',
      neighbors       => $neighbors_list,
      bind_service    => 'anycast-healthchecker.service',
      bfd             => $bfd,
      require         => Class['::bird::anycast_healthchecker'],
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
      ensure    => $vip_params['ensure'],
      address   => $vip_params['address'],
      check_cmd => $vip_params['check_cmd'],
    }
  }
}
