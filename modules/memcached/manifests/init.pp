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
#   Default: 48
#
# [*enable_tls*]
#   Configure mcrouter using TLS on external interfaces. This
#   parameter is only supported on memcached 1.6. On Buster a
#   TLS-enabled build is provided in component/memcached16 and
#   on Bullseye in component/memcached-tls.
#   Default: false
#
# [*enable_16*]
#   Debian Buster has memcached 1.5.6. If this option is enabled
#   a 1.6 backport gets installed. This backport also has TLS
#   enabled. On Bullseye this option isn't needed, it has 1.6.9
#   by default. If you however need TLS on Bullseye, see the
#   'enable_tls' option.
#   Default: false
#
# [*notls_port]
#   By default, when we `enable_tls`, the host will listen
#   `port` for TLS connections. By defining a `notls_port`,
#    we have the ability to listen for unencrypted connections
#    in a different port.
#
# [*enlable_tls_localhost*]
#   By default the socket on localhost will not be wrapped in TLS
#   This is to make debugging easier and support the prometheus exporter.
#   Set this to true to also wrap localhost
#   Default: false
#
# [*ssl_cert*]
#   The public key used for SSL connections
#   Default: undef
#
# [*ssl_key*]
#   The public key used for SSL connections
#   Default: undef
#
# [*extra_options*]
#   A hash of additional command-line options and values.
#
# [*enable_unix_socket*]
#   Listen to a unix socket, disables listening to TCP.
#
# [*unix_socket_name*]
#   Name of the unix socket, eg memcached.sock
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
    Integer                    $size                  = 2000,
    Stdlib::Port               $port                  = 11000,
    Stdlib::IP::Address        $ip                    = '0.0.0.0',
    String                     $version               = 'present',
    Integer                    $min_slab_size         = 48,
    Float                      $growth_factor         = 1.25,
    Hash[String, Any]          $extra_options         = {},
    Boolean                    $enable_16             = false,
    Boolean                    $enable_tls            = false,
    Boolean                    $enable_tls_localhost  = false,
    Boolean                    $enable_unix_socket    = false,
    String                     $unix_socket_name      = 'memcached.sock',
    Optional[Stdlib::Port]     $notls_port            = undef,
    Optional[Stdlib::Unixpath] $ssl_cert              = undef,
    Optional[Stdlib::Unixpath] $ssl_key               = undef,
) {
    if $enable_tls and (!$ssl_key or !$ssl_key) {
        fail('you must provide ssl_cert and ssl_key if you enable_tls')
    }
    if $enable_tls and $enable_unix_socket {
        fail('enabling TLS and using a unix socket are mutually exclusive')
    }
    $notls_listen = $notls_port ? {
        undef   => [],
        default => ["notls:${facts['networking']['ip']}:${notls_port}", "notls:localhost:${notls_port}"]
    }
    if $enable_unix_socket {
        systemd::tmpfile { 'memcached':
            content => 'd /run/memcached 0755 nobody nogroup - -'
        }
    } elsif ($ip == '0.0.0.0' and $enable_tls and !$enable_tls_localhost) {
        # if the ip is 0.0.0.0, indicating all ipv4 interfaces,
        # then we need to split theses addresses out to ensure we
        # have notls on localhost
        $listen = [$facts['networking']['ip'], 'notls:localhost'] + $notls_listen
    } else {
        $listen = [$ip] + $notls_listen
    }
    if $enable_16 {
        # The component for Buster also provides TLS support
        if debian::codename::eq('buster') {
            apt::package_from_component { 'memcached_16':
                component => 'component/memcached16',
                packages  => ['memcached'],
                before    => Service['memcached'],
            }
        }
    } else {
        if debian::codename::eq('bullseye') and $enable_tls {
            apt::package_from_component { 'memcached_tls':
                component => 'component/memcached-tls',
                packages  => ['memcached'],
                priority  => 1002,
                before    => Service['memcached'],
            }
        } else {
            package { 'memcached':
                ensure => $version,
                before => Service['memcached'],
            }
        }
    }

    if $enable_tls {
        $override = true
        if ! $enable_16 and debian::codename::eq('buster'){
            fail('You must set \$enable_16 when using \$enable_tls on Buster')
        }
    } else {
        $override = false
    }

    file { '/etc/memcached.conf':
        content => '# Refer to memcached.service unit for configuration.',
    }

    systemd::service { 'memcached':
        ensure   => present,
        override => $override,
        content  => systemd_template('memcached'),
    }

    # Prefer a direct check if memcached is not running on localhost.
    if $enable_unix_socket {
        nrpe::monitor_service { 'memcached_socket':
            description  => 'memcached socket',
            nrpe_command => "/usr/lib/nagios/plugins/check_tcp -H /run/memcached/${$unix_socket_name} --timeout=2",
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Memcached',
        }
    # Prefer a direct check if memcached is not running on localhost.
    } elsif $ip == '127.0.0.1' {
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
