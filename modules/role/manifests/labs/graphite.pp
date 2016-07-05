# = Class: role::labs::graphite
# Sets up graphite instance for monitoring labs, running on production hardware.
# Instance is open to all, no password required to see metrics
class role::labs::graphite {

    class { 'role::graphite::base':
        storage_dir => '/srv/carbon',
        auth        => false,
        hostname    => 'graphite.wmflabs.org',
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

    ferm::service { 'carbon_c_relay-local_relay_udp':
        proto  => 'udp',
        port   => '1903',
        srange => '@resolve(labmon1001.eqiad.wmnet)',
    }

    ferm::service { 'carbon_c_relay-local_relay_tcp':
        proto  => 'tcp',
        port   => '1903',
        srange => '@resolve(labmon1001.eqiad.wmnet)',
    }

    ferm::service { 'statsite_udp':
        proto  => 'udp',
        port   => '8125',
        srange => '$LABS_NETWORKS',
    }

    ferm::service { 'statsite_tcp':
        proto  => 'udp',
        port   => '8125',
        srange => '$LABS_NETWORKS',
    }

    ferm::service { 'carbon_c_relay-frontend_relay_udp':
        proto  => 'udp',
        port   => '2003',
        srange => '$LABS_NETWORKS',
    }

    ferm::service { 'carbon_c_relay-frontend_relay_tcp':
        proto  => 'tcp',
        port   => '2003',
        srange => '$LABS_NETWORKS',
    }

    ferm::service { 'carbon_pickled':
        proto  => 'tcp',
        port   => '2004',
        srange => '$LABS_NETWORKS',
    }
}
