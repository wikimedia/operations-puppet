# == Class: bird::base
#
# Installs and configure Bird
# Configure Ferm
#
#
class profile::bird::anycast(
  $bfd = hiera('profile::bird::bfd', true),
  $neighbors_list = hiera('profile::bird::neighbors_list', []),
  $bind_service = hiera('profile::bird::bind_service', ''),
  $advertise_vips = hiera('profile::bird::advertise_vips', undef),
){

  $neighbors_for_ferm = join($neighbors_list, ' ')

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
    ferm::service { 'bird-bfd-multi-ctl':  # Multihop BFD
        proto  => 'udp',
        port   => '4784',
        srange => "(${neighbors_for_ferm})",
        before => Class['::bird'],
    }
  }

  if $advertise_vips {
      $vips_defaults = {
          interface => 'lo',
          options   => 'label lo:anycast',
          before    => Class['::bird']
      }
      create_resources(interface::ip, $advertise_vips, $vips_defaults)
  }

  class { '::bird':
      config_template => 'bird/bird_anycast.conf.erb',
      neighbors       => $neighbors_list,
      bind_service    => $bind_service,
      bfd             => $bfd,
      require         => Service['ferm'],
  }
}
