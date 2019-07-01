# == Class: pmacct
#
# Install and manage Fastnetmon
#
# === Parameters
#
#  [*networks*]
#    List of Networks we care about
#    Default: []
#  [*graphite_host*]
#    Hostname of the Graphite ingester
#    Optional

class fastnetmon(
  Array[Stdlib::IP::Address,1] $networks = [],
  Optional[Stdlib::Host] $graphite_host,
  ) {

    require_package('fastnetmon')

    file { '/etc/fastnetmon.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('fastnetmon/fastnetmon.conf.erb'),
        require => Package['fastnetmon'],
        notify  => Service['fastnetmon'],
    }

    file { '/etc/networks_list':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('fastnetmon/networks_list.erb'),
        require => Package['fastnetmon'],
        notify  => Service['fastnetmon'],
    }

    service { 'fastnetmon':
        ensure => running,
        enable => true,
    }
}
