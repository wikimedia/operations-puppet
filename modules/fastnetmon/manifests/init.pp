# SPDX-License-Identifier: Apache-2.0
# == Class: fastnetmon
#
# Install and manage Fastnetmon
#
# === Parameters
#
#  [*networks*]
#    List of Networks we care about
#    Default: []
#
#  [*thresholds_overrides*]
#    Dict of exceptions to the global thresholds
#    Default: []
#
#  [*graphite_host*]
#    Hostname of the Graphite ingester
#    Optional
#
#  [*icinga_dir*]
#    Directory to write a notification file in the event of an attack, to be picked up by an Icinga check
#    Optional

class fastnetmon(
  Array[Stdlib::IP::Address,1] $networks = [],
  Hash[String, Hash[String, Any]] $thresholds_overrides = [],
  Optional[Stdlib::Host] $graphite_host = undef,
  Optional[Stdlib::Unixpath] $icinga_dir = undef,
  ) {

    ensure_packages(['fastnetmon','python3-geoip2'])

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

    file { '/usr/local/bin/fastnetmon_notify.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/fastnetmon/fastnetmon_notify.py',
    }

    file { '/usr/local/bin/fastnetmon_notify':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('fastnetmon/fastnetmon_notify.sh.erb'),
    }

    if $icinga_dir {
        file { $icinga_dir:
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    service { 'fastnetmon':
        ensure => running,
        enable => true,
    }
    profile::auto_restarts::service { 'fastnetmon': }
}
