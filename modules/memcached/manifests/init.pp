# == Class: memcached
#
# Memcached is a general-purpose, in-memory key-value store.
#
# === Parameters
#
# [*size*]
#   Instance size in megabytes (default: 2000).
#
# [*port*]
#   Port to listen on (default: 11000).
#
# [*ip*]
#   IP address to listen on (default: '0.0.0.0').
#
# [*version*]
#   Package version to install, or 'present' for any version
#   (default: 'present').
#
# [*growth_factor*]
#   Multiplier for computing the sizes of memory chunks that items
#   are stored in. Corresponds to memcached's -f parameter (default: '1.05').
#
# [*extra_options*]
#   A hash of additional command-line options and values.
#
# === Examples
#
#  class { '::memcached':
#    size => 100,
#    port => 11211,
#    ip   => '127.0.0.1',
#  }
#
class memcached(
    $size          = 2000,
    $port          = 11000,
    $ip            = '0.0.0.0',
    $version       = 'present',
    $growth_factor = 1.05,
    $extra_options = {},
    ) {

    package { 'memcached':
        ensure => $version,
        before => Service['memcached'],
    }

    # Debian still installs both, but then simply ignores them.
    if $::initsystem != 'systemd' {
        file { '/etc/memcached.conf':
            content => template('memcached/memcached.conf.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            before  => Service['memcached'],
        }

        file { '/etc/default/memcached':
            source => 'puppet:///modules/memcached/memcached.default',
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            before => Service['memcached'],
        }
    }

    base::service_unit { 'memcached':
        ensure         => present,
        systemd        => systemd_template('memcached'),
        strict         => false,
        service_params => {
            enable => true
        }
    }

    # Prefer a direct check if memcached is not running on localhost.

    if $ip == '127.0.0.1' {
        nrpe::monitor_service { 'memcached':
            description  => 'Memcached',
            nrpe_command => "/usr/lib/nagios/plugins/check_tcp -H ${ip} -p ${port}",
        }
    } else {
        monitoring::service { 'memcached':
            description   => 'Memcached',
            check_command => "check_tcp!${port}",
        }
    }

    include ::standard

    diamond::collector { 'Memcached':
        ensure => 'absent'
    }
}
