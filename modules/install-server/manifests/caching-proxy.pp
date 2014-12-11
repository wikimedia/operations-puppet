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
    file { '/etc/squid3/squid.conf':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/install-server/squid3-apt-proxy.conf',
        require => Package['squid3'],
    }

    file { '/etc/logrotate.d/squid3':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/install-server/squid3-logrotate',
        require => Package['squid3'],
    }

    package { 'squid3':
        ensure => installed,
    }

    service { 'squid3':
        ensure    => running,
        require   => [ Package['squid3'], File['/etc/squid3/squid.conf'] ],
        subscribe => File['/etc/squid3/squid.conf'],
    }
}
