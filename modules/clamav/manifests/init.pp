# == Class: clamav
#
# This class installs & manages ClamAV, http://www.clamav.net/
#
# == Parameters
#
# [*proxy*]
#   An HTTP proxy to use for fetching freshclam updates. Optional.

class clamav($proxy=undef) {
    package { [ 'clamav-daemon', 'clamav-freshclam' ]:
        ensure => present,
    }

    exec { 'add clamav to Debian-exim':
        command => 'usermod -a -G Debian-exim clamav',
        unless  => 'id -Gn clamav | grep -q Debian-exim',
        path    => '/bin:/sbin:/usr/bin:/usr/sbin',
        require =>  Package['clamav-daemon'],
    }

    file { '/etc/clamav/clamd.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/clamav/clamd.conf',
        require => Package['clamav-daemon'],
    }

    # Add proxy settings to freshclam
    if $proxy {
        $proxy_arr = split($proxy, ':')
        $proxy_host = $proxy_arr[0]
        $proxy_port = $proxy_arr[1]

        file_line { 'freshclam_proxyserver':
            line   => "HTTPProxyServer ${proxy_host}",
            match  => "^HTTPProxyServer",
            path   => '/etc/clamav/freshclam.conf',
            notify => Service['clamav-freshclam'],
        }
        file_line { 'freshclam_proxyport':
            line   => "HTTPProxyPort ${proxy_port}",
            match  => "^HTTPProxyPort",
            path   => '/etc/clamav/freshclam.conf',
            notify => Service['clamav-freshclam'],
        }
    }

    service { 'clamav-freshclam':
        ensure  => running,
        require => Package['clamav-freshclam'],
    }

    service { 'clamav-daemon':
        ensure    => running,
        require   => File['/etc/clamav/clamd.conf'],
        subscribe => File['/etc/clamav/clamd.conf'],
    }
}
