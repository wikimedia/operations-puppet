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

  # TODO not sure if we can allow a port range, allowing all UDP for now
  # neighbors_list are trusted routers anyway
  if $bfd {
    ferm::service { 'bird-bfd':
        proto  => 'udp',
        #port   => '49152-65535',
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
