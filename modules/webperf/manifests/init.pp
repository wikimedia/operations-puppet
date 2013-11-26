# == Class: webperf
#
# This Puppet module provisions a set of client-side performance
# monitoring scripts for Wikimedia sites.
#
class webperf {
    package { 'phantomjs':
        ensure => present,
    }

    group { 'webperf':
        ensure => present,
    }

    user { 'webperf':
        ensure => present,
        gid    => 'webperf',
        shell  => '/bin/false',
        home   => '/nonexistent',
        system => true,
    }

    file { '/srv/webperf':
        ensure => directory,
    }

    file { '/srv/webperf/asset-check.js':
        source  => 'puppet:///modules/webperf/asset-check.js',
        require => Package['phantomjs'],
    }

    file { '/srv/webperf/asset-check.py':
        source  => 'puppet:///modules/webperf/asset-check.py',
        require => [ File['/srv/webperf/asset-check.js'],
Package['ganglia-monitor'] ],
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
