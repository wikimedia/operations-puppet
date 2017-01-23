# Class: install_server::dhcp_server
#
# This class installs isc-dhcp-server and configures it
#
# Parameters:
#
# Actions:
#       Install isc-dhcp-server and populate configuration directory
#
# Requires:
#
# Sample Usage:
#   include install_server::dhcp_server

class install_server::dhcp_server {
    file { '/etc/dhcp':
        ensure  => directory,
        require => Package['isc-dhcp-server'],
        recurse => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/install_server/dhcpd',
    }

    package { 'isc-dhcp-server':
        ensure => present,
    }

    service { 'isc-dhcp-server':
        ensure    => running,
        require   => [
            Package['isc-dhcp-server'],
            File['/etc/dhcp']
        ],
        subscribe => File['/etc/dhcp'],
    }
}
