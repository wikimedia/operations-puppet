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

    $dhcp_active_server = hiera('dhcp_active_server')

    if $::hostname == $dhcp_active_server {
        $ensure_dhcp = 'running'
    } else {
        $ensure_dhcp = 'stopped'
    }

    service { 'isc-dhcp-server':
        ensure    => $ensure_dhcp,
        require   => [
            Package['isc-dhcp-server'],
            File['/etc/dhcp']
        ],
        subscribe => File['/etc/dhcp'],
    }
}
