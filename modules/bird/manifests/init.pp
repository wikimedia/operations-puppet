# SPDX-License-Identifier: Apache-2.0
# @summary Installs Bird2 and its Prometheus metrics exporter
#
# @param neighbors
#   List of BGP neighbors
#
# @param config_template
#   Specifiy which Bird config to use.
#   Only anycast exists for now, but it could be extended in the future.
#
# @param bfd
#   Enables BFD with the BGP peer (300ms*3)
#
# @param bind_service
#   Allows to bind the bird service to another service (watchdog-like)
#
# @param ipv4_src
#   IPv4 address to use for BGP session, also used as router ID
#
# @param ipv6_src
#   IPv6 address to use for BGP session
#
# @param do_ipv6
#   Whether to enable IPv6 support. default: false.
#
# @param multihop
#   If the neighbors are direct or not. default: true.

class bird(
  Array[Stdlib::IP::Address] $neighbors,
  String                     $config_template = 'bird/bird_anycast.conf.erb',
  Boolean                    $bfd             = true,
  Optional[String]           $bind_service    = undef,
  Boolean                    $do_ipv6         = false,
  Boolean                    $multihop        = true,
  Stdlib::IP::Address        $ipv4_src        = $facts['ipaddress'],
  Stdlib::IP::Address        $ipv6_src        = $facts['ipaddress6'],
  ){

  ensure_packages(['prometheus-bird-exporter'])

  $neighbors_v4 = $neighbors.filter |$neighbor| { $neighbor =~ Stdlib::IP::Address::V4::Nosubnet }
  $neighbors_v6 = $neighbors.filter |$neighbor| { $neighbor =~ Stdlib::IP::Address::V6::Nosubnet }

  # Install the backported bird2 package from bullseye if the host is buster.
  if debian::codename::eq('buster') {
      apt::package_from_component { 'bird2':
          component => 'component/bird2',
      }
  } else {
    ensure_packages(['bird2'])
  }

  systemd::service { 'bird':
      ensure         => present,
      restart        => true,
      content        => template('bird/bird.service.erb'),
      require        => [
          Package['bird2'],
      ],
      service_params => {
          restart => 'systemctl reload bird.service',
      },
  }

  systemd::service { 'bird6':
    ensure  => absent,
    restart => true,
    content => template('bird/bird.service.erb'),
  }

  file { '/etc/bird/bird6.conf':
      ensure  => absent,
  }

  file { '/etc/bird/bird.conf':
      ensure  => present,
      owner   => 'bird',
      group   => 'bird',
      mode    => '0640',
      content => template($config_template),
      notify  => Systemd::Service['bird'],
  }

  service { 'prometheus-bird-exporter':
      ensure     => running,
      enable     => true,
      hasrestart => true,
      require    => Package['prometheus-bird-exporter'],
  }

  file { '/etc/default/prometheus-bird-exporter':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0444',
      source => 'puppet:///modules/bird/prometheus-bird-exporter.default',
      notify => Service['prometheus-bird-exporter'],
  }

  nrpe::monitor_service { 'bird':
      ensure       => present,
      description  => 'Bird Internet Routing Daemon',
      nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C bird',
      notes_url    => 'https://wikitech.wikimedia.org/wiki/Anycast#Bird_daemon_not_running',
  }
}
