#

class install-server::caching-proxy {

    file { '/etc/squid/squid.conf':
        ensure  => present,
        require => Package[squid],
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        path    => '/etc/squid/squid.conf',
        source  => 'puppet:///files/squid/apt-proxy.conf',
    }

    file { '/etc/logrotate.d/squid':
        ensure  => present,
        require => Package[squid],
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        path    => '/etc/logrotate.d/squid',
        source  => 'puppet:///files/logrotate/squid',
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
