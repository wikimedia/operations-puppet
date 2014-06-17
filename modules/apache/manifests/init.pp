# == Class: apache
#
# Provisions Apache web server package and service.
#
# === Parameters
#
# [*service_enable*]
#   Whether the Apache service should be enabled. Boolean; true by default.
#
# === Example
#
#  class { 'apache':
#    service_enable => false,
#  }
#
class apache( $service_enable = true ) {
    validate_bool($service_enable)

    # Strive for seamless Apache 2.2 / 2.4 compatibility
    include apache::mod::access_compat
    include apache::mod::filter
    include apache::mod::version

    # transitional!
    package { 'httpd':
        name   => 'apache2.2-common',
        ensure => installed,
    }

    package { [ 'apache2', 'apache2-mpm-prefork' ]:
        ensure => present,
    }

    # Dirty hack. Ori will fix/revert by EOD 17-Jun-2014.
    service { 'httpd':
        provider  => base,
        start     => '/bin/true',
        stop      => '/bin/true',
    }

    service { 'apache2':
        provider => base,
        start    => '/bin/true',
        stop     => '/bin/true',
    }

    file { '/etc/apache2/sites-enabled':
        ensure  => directory,
        recurse => true,
        purge   => true,
        notify  => Service['httpd'],
        require => Package['httpd'],
    }
}
