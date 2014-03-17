# Class: install-server::dhcp-server
#
# This class installs dhcp3-server and configures it
#
# Parameters:
#
# Actions:
#       Install dhcp3-server and populate configuration directory
#
# Requires:
#
# Sample Usage:
#   include install-server::dhcp-server

class install-server::dhcp-server {
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '12.04') >= 0 {
        $confdir = '/etc/dhcp/'
        $package_service_name = 'isc-dhcp-server'
    } else {
        $confdir = '/etc/dhcp3'
        $package_service_name = 'dhcp3-server'
    }
    file { $confdir:
        ensure      => directory,
        require     => Package[dhcp3-server],
        recurse     => true,
        owner       => 'root',
        group       => 'root',
        mode        => '0444',
        source      => 'puppet:///modules/install-server/dhcpd',
    }

    package { $package_service_name:
        ensure => latest;
    }

    service { $package_service_name:
        ensure    => running,
        require   => [ Package[$package_service_name],
                       File[ $confdir ]
                      ],
        subscribe => File[ $confdir ],
    }
}
