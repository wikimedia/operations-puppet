# Class: url_downloader
#
# This class installs squid as a forward proxy for fetching URLs
#
# Parameters:
#   $service_ip
#       The IP on which the proxy listens on and uses to fetch URLs
#
# Actions:
#       Install squid and configure it as a forward fetching proxy
#
# Requires:
#
# Sample Usage:
#       class { '::url_downloader':
#           service_ip  => '10.10.10.10' # Probably a public ip though
#       }
class url_downloader($service_ip) {
    file { '/etc/squid3/squid.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('url_downloader/squid.conf.erb'),
    }

    file { '/etc/logrotate.d/squid3':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source => 'puppet:///modules/url_downloader/squid3-logrotate',
    }

    package { 'squid3':
        ensure => installed,
    }

    service { 'squid3':
        ensure => running,
    }

    Package['squid3'] -> Service['squid3']
    Package['squid3'] -> File['/etc/logrotate.d/squid3']
    Package['squid3'] -> File['/etc/squid3/squid.conf']
    File['/etc/squid3/squid.conf'] ~> Service['squid3'] # also notify
}
