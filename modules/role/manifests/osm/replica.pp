class role::osm::replica (
    $osm_master = undef,
) {
    include role::osm::common
    include postgresql::postgis
    include passwords::osm
    include ::profile::base::firewall
    include ::profile::prometheus::postgres_exporter
    # Note: This is here to illustrate the fact that the replica is expected to
    # have the same dbs as the master.
    #postgresql::spatialdb { 'gis': }

    system::role { 'osm::replica':
        ensure      => 'present',
        description => 'openstreetmaps db replica',
    }

    class {'postgresql::slave':
        master_server    => $osm_master,
        replication_pass => $passwords::osm::replication_pass,
        includes         => ['tuning.conf'],
        root_dir         => $role::osm::common::root_dir,
    }
}
