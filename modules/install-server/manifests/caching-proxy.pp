# Class: install-server::caching-proxy
#
# This class installs squid and configures it
#
# Parameters:
#
# Actions:
#       Install squid and configure it as a caching forward proxy
#
# Requires:
#
# Sample Usage:
#   include install-server::caching-proxy

class install-server::caching-proxy {
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '12.04') >= 0 {
        $confdir = '/etc/squid3'
        $package_name = 'squid3'
        $service_name = 'squid3'
    } else {
        $confdir = '/etc/squid'
        $package_name = 'squid'
        $service_name = 'squid'
    }

    file { "${confdir}/squid.conf":
        ensure  => present,
        require => Package[$package_name],
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => "puppet:///modules/install-server/${package_name}-apt-proxy.conf",
    }

    file { '/etc/logrotate.d/squid':
        ensure  => present,
        require => Package[$package_name],
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => "puppet:///modules/install-server/${package_name}-logrotate",
    }

    package { $package_name:
        ensure => latest,
    }

    service { $service_name:
        ensure      => running,
        require     => [
                        File["${confdir}/squid.conf"],
                        Package[$package_name]
                       ],
        subscribe   => File["${confdir}/squid.conf"],
    }
}
