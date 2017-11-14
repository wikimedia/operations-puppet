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

  ferm::service { 'bird-bgp':
      proto  => 'tcp',
      port   => '179',
      srange => $neighbors_list,
  }

  if $bfd {
    ferm::service { 'bird-bfd-control':
        proto  => 'udp',
        port   => '3784',
        srange => $neighbors_list,
    }
    ferm::service { 'bird-bfd-echo':
        proto  => 'udp',
        port   => '3785',
        srange => $neighbors_list,
    }
  }

  if $advertise_vips {
      $vips_defaults = {
          interface => 'lo',
          options   => 'label lo:anycast'
      }
      create_resources(interface::ip, $advertise_vips, $vips_defaults)
  }

  class { '::bird':
      config_template => 'bird/bird_anycast.conf.erb',
      neighbors       => $neighbors_list,
      bind_service    => $bind_service,
      bfd             => $bfd,
  }
}
