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

    package { [ 'apache2', 'apache2-mpm-prefork' ]:
        ensure => present,
    }

    service { 'apache2':
        ensure  => $service_enable,
        enable  => $service_enable,
        require => Package['apache2'],
    }

    file { '/etc/apache2/sites-enabled':
        ensure  => directory,
        recurse => true,
        purge   => true,
        notify  => Service['apache2'],
        require => Package['apache2'],
    }

    # Provision Apache modules before sites
    Apache::Mod_conf <| |> -> Apache::Site <| |>
}
