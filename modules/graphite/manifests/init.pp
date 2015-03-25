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
    $carbon_settings,
    $storage_schemas,
    $storage_aggregation = {},
    $storage_dir = '/var/lib/carbon',
    $whisper_lock_writes = false,
    ) {
    package { ['graphite-carbon', 'python-whisper']: }

    # force installation of python-twisted-core separatedly, there seem to be a
    # race condition with dropin.cache generation when apt-get installing
    # graphite and twisted at the same time.
    # https://bugs.launchpad.net/graphite/+bug/833196
    package { 'python-twisted-core':
        ensure => installed,
        before => Package['graphite-carbon'],
    }

    $carbon_service_defaults = {
        log_updates              => false,
        log_cache_hits           => false,
        log_cache_queue_sorts    => false,
        log_listener_connections => false,
        whisper_lock_writes      => $whisper_lock_writes,
        user                     => undef,  # Don't suid; Upstart will do it for us.
        conf_dir                 => '/etc/carbon',
        log_dir                  => '/var/log/carbon',
        pid_dir                  => '/var/run/carbon',
        storage_dir              => $storage_dir,
        whitelists_dir           => "${storage_dir}/lists",
        local_data_dir           => "${storage_dir}/whisper",
    }

    $carbon_defaults = {
        cache => $carbon_service_defaults,
        relay => $carbon_service_defaults,
    }

    file { $storage_dir:
        ensure  => directory,
        owner   => '_graphite',
        group   => '_graphite',
        mode    => '0755',
        before  => Service['carbon'],
        require => Package['graphite-carbon'],
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

    file { '/etc/carbon/storage-aggregation.conf':
        content => configparser_format($storage_aggregation),
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

    file { '/etc/default/graphite-carbon':
        source => 'puppet:///modules/graphite/graphite-carbon',
        mode   => '0644',
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
