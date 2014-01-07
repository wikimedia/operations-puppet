# == Class: webperf::asset_check
#
# Provisions a service which gather stats about static assets count
# and size using a headless browser instance. Stats are forwarded to
# Ganglia using gmetric.
#
class webperf::asset_check {
    package { 'phantomjs':
        ensure => present,
    }

    file { '/srv/webperf/asset-check.js':
        source  => 'puppet:///modules/webperf/asset-check.js',
        require => Package['phantomjs'],
    }

    file { '/srv/webperf/asset-check.py':
        source  => 'puppet:///modules/webperf/asset-check.py',
        require => [ File['/srv/webperf/asset-check.js'], Package['ganglia-monitor'] ],
    }

    file { '/etc/init/asset-check.conf':
        source  => 'puppet:///modules/webperf/asset-check.conf',
        require => [ File['/srv/webperf/asset-check.py'], User['webperf'] ],
    }

    service { 'asset-check':
        ensure   => running,
        provider => 'upstart',
        require  => File['/etc/init/asset-check.conf'],
    }
}
