# == Class: graphite
#
# Graphite is a monitoring tool that stores numeric time-series data and
# renders graphs of this data on demand. It consists of the following software
# components:
#
#  - Carbon, a daemon that listens for time-series data
#  - Carbon-c-relay, an high-performance metric router
#  - Whisper, a database library for storing time-series data
#  - Graphite webapp, a webapp which renders graphs on demand
#
class graphite(
    $carbon_settings,
    $c_relay_settings,
    $storage_schemas,
    $storage_aggregation = {},
    $storage_dir = '/var/lib/carbon',
    ) {
    require_package('graphite-carbon', 'python-whisper', 'carbon-c-relay')

    $carbon_service_defaults = {
        log_updates              => false,
        log_cache_hits           => false,
        log_cache_queue_sorts    => false,
        log_listener_connections => false,
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
        require => Class['packages::graphite_carbon'],
    }

    file { '/etc/carbon/storage-schemas.conf':
        content => configparser_format($storage_schemas),
        require => Class['packages::graphite_carbon'],
        notify  => Service['carbon'],
    }

    file { '/etc/carbon/carbon.conf':
        content => configparser_format($carbon_defaults, $carbon_settings),
        require => Class['packages::graphite_carbon'],
        notify  => Service['carbon'],
    }

    file { '/etc/carbon/storage-aggregation.conf':
        content => configparser_format($storage_aggregation),
        require => Class['packages::graphite_carbon'],
        notify  => Service['carbon'],
    }

    file { '/etc/carbon/local-relay.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('graphite/local-relay.conf.erb'),
        notify  => Service['carbon/local-relay'],
    }

    # NOTE: the service is named local-relay as opposed to c-relay otherwise
    # we'd have these very similar but different names:
    # service carbon-c-relay # from debian package, the standard relay
    # service carbon/c-relay # from this module, forwarding to local carbon-cache
    file { '/etc/init/carbon/local-relay.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('graphite/local-relay.upstart.conf.erb'),
        notify  => Service['carbon/local-relay'],
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

    service { 'carbon/local-relay':
        ensure   => 'running',
        provider => 'upstart',
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
