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
    $storage_dir         = '/var/lib/carbon',
    $whisper_lock_writes = false,
) {
    package { [ 'graphite-carbon', 'python-whisper' ]:
        ensure => installed,
    }

    # force installation of python-twisted-core separatedly, there seem to be a
    # race condition with dropin.cache generation when apt-get installing
    # graphite and twisted at the same time.
    # https://bugs.launchpad.net/graphite/+bug/833196
    package { 'python-twisted-core':
        ensure => installed,
        before => Package['graphite-carbon'],
    }

    $default_c_relay_settings = {
            'carbon-cache' => [
                '127.0.0.1:2103=a',
                '127.0.0.1:2203=b',
                '127.0.0.1:2303=c',
                '127.0.0.1:2403=d',
                '127.0.0.1:2503=e',
                '127.0.0.1:2603=f',
                '127.0.0.1:2703=g',
                '127.0.0.1:2803=h',
            ],
            'forward_clusters' => {
              'default' => [
                  'localhost:1903',
              ],
            },
            'cluster_tap' => {},
            'cluster_routes' => {},
    }

    class { '::graphite::carbon_c_relay':
        c_relay_settings => merge($default_c_relay_settings, $c_relay_settings),
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

    # Dummy config file to use with carbonate during metric sync/backfill
    file { '/etc/carbon/carbonate.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['graphite-carbon'],
        content => "[main]\n",
    }

    file { '/var/log/carbon':
        ensure  => directory,
        owner   => '_graphite',
        group   => '_graphite',
        mode    => '0755',
        before  => Service['carbon'],
        require => Package['graphite-carbon'],
    }

    file { '/var/run/carbon':
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

    # disable default carbon-cache via systemctl
    exec { 'mask_carbon-cache':
        command => '/bin/systemctl mask carbon-cache.service',
        creates => '/etc/systemd/system/carbon-cache.service',
        before  => Package['graphite-carbon'],
    }

    # create required directory in /run at reboot, don't wait for a puppet
    # run to fix it
    systemd::tmpfile { 'graphite':
        content => 'd /var/run/carbon 0755 _graphite _graphite',
    }

    rsyslog::conf { 'graphite':
        source => 'puppet:///modules/graphite/rsyslog.conf',
    }

    logrotate::rule { 'graphite':
        file_glob      => '/var/log/uwsgi-graphite-web.log',
        frequency      => 'daily',
        date_ext       => true,
        date_yesterday => true,
        rotate         => 14,
        missing_ok     => true,
        no_create      => true,
        compress       => true,
        post_rotate    => 'service rsyslog rotate >/dev/null 2>&1 || true',
    }

    systemd::unit { 'carbon-cache@.service':
        ensure  => present,
        content => systemd_template('carbon-cache@')
    }

    systemd::service { 'carbon':
        ensure  => present,
        content => systemd_template('carbon'),
        restart => true,
    }

    graphite::carbon_cache_instance { 'a': }
    graphite::carbon_cache_instance { 'b': }
    graphite::carbon_cache_instance { 'c': }
    graphite::carbon_cache_instance { 'd': }
    graphite::carbon_cache_instance { 'e': }
    graphite::carbon_cache_instance { 'f': }
    graphite::carbon_cache_instance { 'g': }
    graphite::carbon_cache_instance { 'h': }
}
