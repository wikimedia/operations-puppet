# == Class: wdq-mm
#
# Class for setting up an instance of Magnus' WDQ
class wdq-mm {
    package { 'wdq-mm':
        ensure => latest,
    }

    service { 'wdq-mm':
        ensure  => running,
        require => Package['wdq-mm'],
    }

    package { 'monit':
        ensure => present,
    }

    service { 'monit':
        ensure  => stopped,
        require => Package['monit'],
    }

    file { '/etc/monit/conf.d/wdq-mm':
        source  => 'puppet:///modules/wdq-mm/monitrc',
        require => [
            Package['monit'],
            Package['wdq-mm'],
        ],
        notify  => Service['monit'],
    }
}
