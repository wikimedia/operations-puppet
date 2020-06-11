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
#   are stored in. Corresponds to memcached's -f parameter, and it
#   wil dictate the distribution of slab sizes.
#   Note: change the default only if you know what you are doing.
#   Default: 1.25
#
# [*growth_factor*]
#   This is the value of the smallest slab that memcached will use.
#   All the other slabs will be created using the growth_factor
#   parameter.
#   Note: change the default only if you know what you are doing.
#   Defaulf: 48
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
    Integer $size                    = 2000,
    Stdlib::Port $port               = 11000,
    Stdlib::IP::Address $ip          = '0.0.0.0',
    String $version                  = 'present',
    Integer $min_slab_size           = 48,
    Float $growth_factor             = 1.25,
    Hash[String, Any] $extra_options = {},
    Boolean $enable_16               = false,
) {

    if $enable_16 {
        apt::package_from_component { 'memcached_16':
            component => 'component/memcached16',
            packages  => ['memcached'],
            before    => Service['memcached'],
        }
    } else {
        package { 'memcached':
            ensure => $version,
            before => Service['memcached'],
        }
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
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Memcached',
        }
    } else {
        monitoring::service { 'memcached':
            description   => 'Memcached',
            check_command => "check_tcp!${port}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Memcached',
        }
    }

}
