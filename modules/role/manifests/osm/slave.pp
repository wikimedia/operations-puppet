class role::osm::slave (
    $osm_master = undef,
) {
    include role::osm::common
    include postgresql::postgis
    include passwords::osm
    include ::base::firewall
    # Note: This is here to illustrate the fact that the slave is expected to
    # have the same dbs as the master.
    #postgresql::spatialdb { 'gis': }

    system::role { 'osm::slave':
        ensure      => 'present',
        description => 'openstreetmaps db slave',
    }

    class {'postgresql::slave':
        master_server    => $osm_master,
        replication_pass => $passwords::osm::replication_pass,
        includes         => 'tuning.conf',
        root_dir         => $role::osm::common::root_dir,
    }

    class { 'prometheus::postgres_exporter':
        require => Class['postgresql::slave'],
    }
}
