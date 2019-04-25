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

    systemd::service { 'memcached':
        ensure  => present,
        content => systemd_template('memcached'),
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
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Memcached',
        }
    }

}
