# = Class: role::labs::graphite
# Sets up graphite instance for monitoring labs, running on production hardware.
# Instance is open to all, no password required to see metrics
class role::labs::graphite {

    class { 'role::graphite::base':
        storage_dir      => '/srv/carbon',
        auth             => false,
        hostname         => 'graphite.wmflabs.org',
        c_relay_settings => {
            'cluster_tap' => [
                ['^.*\.cpu\.total.*$', 'graphite_exporter'],
                ['^.*memory\..*$', 'graphite_exporter'],
                ['^.*diskspace\..*$', 'graphite_exporter'],
                ['^.*iostat\..*$', 'graphite_exporter'],
                ['^.*loadavg\..*$', 'graphite_exporter'],
                ['^.*network\..*$', 'graphite_exporter'],
                ['^.*udp\..*$', 'graphite_exporter'],
            ]
        },
    }

    class { 'prometheus::graphite_exporter':
        config_file => 'graphite_exporter_labs.conf',
    }

    include graphite::labs::archiver

    file { '/var/lib/carbon':
        ensure  => link,
        target  => '/srv/carbon',
        owner   => '_graphite',
        group   => '_graphite',
        require => Class['role::graphite::base']
    }

    include role::statsite
}
