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

    file { '/etc/squid/squid.conf':
        ensure  => present,
        require => Package[squid],
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/install-server/squid-apt-proxy.conf',
    }

    file { '/etc/logrotate.d/squid':
        ensure  => present,
        require => Package[squid],
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/install-server/squid-logrotate',
    }

    package { 'squid':
        ensure => latest,
    }

    service { 'squid':
        ensure      => running,
        require     => [ File['/etc/squid/squid.conf'], Package[squid] ],
        subscribe   => File['/etc/squid/squid.conf'],
    }

}
