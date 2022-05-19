# SPDX-License-Identifier: Apache-2.0
# == Class: bird
#
# Installs Bird and its prometheus metrics exporter
#
# === Parameters
#
# [*neighbors*]
#   List of BGP neighbors
#
# [*config_template*]
#   Specifiy which Bird config to use.
#   Only anycast exists for now, but it could be extended in the future.
#
# [*bfd*]
#   Enables BFD with the BGP peer (300ms*3)
#
# [*bind_service*]
#   Allows to bind the bird service to another service (watchdog-like)
#
# [*ipv4_src*]
#   IPv4 address to use for BGP session, also used as router ID
#
# [*ipv6_src*]
#   IPv6 address to use for BGP session
#
# [*do_ipv6*]
#   Whether to enable IPv6 support. default: false.
#
# [*multihop*]
#   If he neighbors are direct or not. default: true.

class bird(
  Array[Stdlib::IP::Address] $neighbors,
  String                     $config_template = 'bird/bird_anycast.conf.epp',
  Boolean                    $bfd             = true,
  Optional[String]           $bind_service    = undef,
  Boolean                    $do_ipv6         = false,
  Boolean                    $multihop        = true,
  Stdlib::IP::Address        $ipv4_src        = $facts['ipaddress'],
  Stdlib::IP::Address        $ipv6_src        = $facts['ipaddress6'],
  ){

  ensure_packages(['bird', 'prometheus-bird-exporter'])

  $neighbors_v4 = $neighbors.filter |$neighbor| { $neighbor =~ Stdlib::IP::Address::V4::Nosubnet }
  $neighbors_v6 = $neighbors.filter |$neighbor| { $neighbor =~ Stdlib::IP::Address::V6::Nosubnet }

  if $bind_service {
    exec { 'bird-systemd-reload-enable':
        command     => 'systemctl daemon-reload; systemctl enable bird.service',
        path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
        refreshonly => true,
    }
    file { '/lib/systemd/system/bird.service':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('bird/bird.service.erb'),
        require => Package['bird'],
        notify  => Exec['bird-systemd-reload-enable'],
    }
    systemd::service { 'bird6':
      ensure         => $do_ipv6.bool2str('present', 'absent'),
      restart        => true,
      content        => template('bird/bird6.service.erb'),
      require        => [
          Package['bird'],
      ],
      service_params => {
          restart => 'systemctl reload bird6.service',
      },
    }
  } else {
    service { 'bird6':
        enable  => true,
        restart => 'systemctl reload bird6.service',
        require => Package['bird'],
    }
  }

  service { 'bird':
      enable  => true,
      restart => 'service bird reload',
      require => Package['bird'],
  }

  file { '/etc/bird/bird.conf':
      ensure  => present,
      owner   => 'bird',
      group   => 'bird',
      mode    => '0640',
      content => epp($config_template, {'neighbors' => $neighbors_v4}),
      notify  => Service['bird'],
  }

  file { '/etc/bird/bird6.conf':
      ensure  => stdlib::ensure($do_ipv6, 'file'),
      owner   => 'bird',
      group   => 'bird',
      mode    => '0640',
      content => epp($config_template, {'do_ipv6' => $do_ipv6, 'neighbors' => $neighbors_v6}),
      notify  => Service['bird6'],
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
      nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:2 -C bird',
      notes_url    => 'https://wikitech.wikimedia.org/wiki/Anycast#Bird_daemon_not_running',
  }
}
