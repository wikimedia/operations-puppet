# == Class: graphite
#
# Graphite is a monitoring tool that stores numeric time-series data and
# renders graphs of this data on demand. It consists of three software
# components:
#
#  - Carbon, a daemon that listens for time-series data
#  - Whisper, a database library for storing time-series data
#  - Graphite webapp, a webapp which renders graphs on demand
#
class graphite(
    $retention,
    $carbon,
) {
    package { 'python-carbon': }
    package { 'python-graphite-web': }
    package { 'python-whisper': }

    file { '/etc/security/limits.d/graphite.conf':
        source => 'puppet:///modules/graphite/graphite.limits.conf',
    }

    group { 'graphite':
        ensure => present,
    }

    user { 'graphite':
        ensure => present,
        gid    => 'graphite',
        shell  => '/bin/false',
        home   => '/nonexistent',
        system => true,
    }

    file { '/opt/graphite':
        ensure  => directory,
        require => Package['python-carbon'],
    }

    file { '/opt/graphite/storage':
        ensure  => directory,
        owner   => 'graphite',
        group   => 'graphite',
        mode    => '0644',
        require => Package['python-carbon'],
    }

    file { '/opt/graphite/conf/storage-schemas.conf':
        content => configparser_format($retention),
        before  => File['/etc/init/carbon'],
    }

    file { '/opt/graphite/conf/carbon.conf':
        content => configparser_format($carbon),
        before  => File['/etc/init/carbon'],
    }

    file { '/etc/init/carbon':
        source  => 'puppet:///modules/graphite/carbon-upstart',
        recurse => true,
    }

    service { 'carbon/init':
        provider => 'upstart',
        require  => [
            File['/etc/init/carbon'],
            User['graphite']
        ],
    }
}
