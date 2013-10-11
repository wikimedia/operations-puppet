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
    file { '/etc/dhcp3/' :
        ensure      => directory,
        require     => Package[dhcp3-server],
        recurse     => true,
        owner       => 'root',
        group       => 'root',
        mode        => '0444',
        source      => 'puppet:///modules/install-server/dhcpd',
    }

    package { 'dhcp3-server':
        ensure => latest;
    }

    service { 'dhcp3-server':
        ensure    => running,
        require   => [ Package[dhcp3-server],
                       File['/etc/dhcp3/' ]
                      ],
        subscribe => File['/etc/dhcp3/' ],
    }
}
