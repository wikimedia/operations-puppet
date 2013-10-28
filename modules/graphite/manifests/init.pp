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
    $storage_schemas,
    $carbon_settings,
) {
    include ::graphite::web

    package { 'graphite-carbon': }
    package { 'python-whisper': }

    $carbon_service_defaults = {
        log_updates => false,  # Don't log Whisper updates.
        user        => undef,  # Don't suid; Upstart will do it for us.
        conf_dir    => '/etc/carbon',
        log_dir     => '/var/log/carbon',
        pid_dir     => '/var/run/carbon',
        storage_dir => '/var/lib/graphite',
    }

    $carbon_defaults = {
        cache => $carbon_service_defaults,
        relay => $carbon_service_defaults,
    }

    file { '/etc/security/limits.d/graphite.conf':
        source => 'puppet:///modules/graphite/graphite.limits.conf',
    }

    file { '/usr/storage/whisper':
        owner  => '_graphite',
        group  => '_graphite',
        mode   => '0755',
        before => Service['carbon'],
    }

    file { '/etc/carbon/storage-schemas.conf':
        content => configparser_format($storage_schemas),
        require => Package['graphite-carbon'],
        notify  => Service['carbon'],
    }

    file { '/etc/carbon/carbon.conf':
        content => configparser_format($carbon_defaults, $carbon_settings),
        require => Package['graphite-carbon'],
        notify  => Service['carbon'],
    }

    file { '/etc/init/carbon':
        source  => 'puppet:///modules/graphite/carbon-upstart',
        recurse => true,
        notify  => Service['carbon'],
    }

    file { '/sbin/carbonctl':
        source => 'puppet:///modules/graphite/carbonctl',
        mode   => '0755',
        before => Service['carbon'],
    }

    service { 'carbon':
        ensure   => 'running',
        provider => 'base',
        restart  => '/sbin/carbonctl restart',
        start    => '/sbin/carbonctl start',
        status   => '/sbin/carbonctl status',
        stop     => '/sbin/carbonctl stop',
    }
}
