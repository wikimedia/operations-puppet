# SPDX-License-Identifier: Apache-2.0
# @summary Installs Bird2 and its Prometheus metrics exporter
#
# @param config_template
#   Specifiy which Bird config to use.
#   Only anycast exists for now, but it could be extended in the future.
#
# @param bfd
#   Enables BFD with the BGP peer (300ms*3)
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
#
# @param bind_service
#   Optional: Allows to bind the bird service to another service (watchdog-like)
#
# @param neighbors
#   Optional: List of BGP neighbors
#

class bird(
  String                               $config_template = 'bird/bird_anycast.conf.erb',
  Boolean                              $bfd             = true,
  Boolean                              $do_ipv6         = false,
  Boolean                              $multihop        = true,
  Stdlib::IP::Address                  $ipv4_src        = $facts['ipaddress'],
  Stdlib::IP::Address                  $ipv6_src        = $facts['ipaddress6'],
  Optional[String]                     $bind_service    = undef,
  Optional[Array[Stdlib::IP::Address]] $neighbors       = undef,
  ){

  ensure_packages(['bird2', 'prometheus-bird-exporter'])

  if $neighbors {
    $_neighbors_list = $neighbors
    $_multihop = $multihop
  } else {
    $_neighbors_list = $do_ipv6 ? {
        true    => [$facts['default_routes']['ipv4'], $facts['default_routes']['ipv6']],
        default => [$facts['default_routes']['ipv4']],
    }
    $_multihop = false
  }

  $neighbors_v4 = $_neighbors_list.filter |$neighbor| { $neighbor =~ Stdlib::IP::Address::V4::Nosubnet }
  $neighbors_v6 = $_neighbors_list.filter |$neighbor| { $neighbor =~ Stdlib::IP::Address::V6::Nosubnet }

  # In module as firewall always needs to be opened to BGP/BFD neighbors
  # prevent code duplication in profiles
  firewall::service { 'bird-bgp':
      proto  => 'tcp',
      port   => 179,
      srange => $_neighbors_list,
  }

  # Ports from https://github.com/BIRD/bird/blob/master/proto/bfd/bfd.h#L28-L30
  if $bfd {
    firewall::service { 'bird-bfd-control':
        proto  => 'udp',
        port   => 3784,
        srange => $_neighbors_list,
    }
    firewall::service { 'bird-bfd-echo':
        proto  => 'udp',
        port   => 3785,
        srange => $_neighbors_list,
    }
    if $_multihop {
      firewall::service { 'bird-bfd-multi-ctl':  # Multihop BFD
          proto  => 'udp',
          port   => 4784,
          srange => $_neighbors_list,
      }
    }
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

  file { '/etc/bird/bird.conf':
      ensure  => present,
      owner   => 'bird',
      group   => 'bird',
      mode    => '0640',
      content => template($config_template),
      notify  => Systemd::Service['bird'],
      require => Package['bird2'],
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
