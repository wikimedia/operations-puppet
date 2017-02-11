class role::osm::slave {
    include role::osm::common
    include postgresql::postgis
    include passwords::osm
    include ::base::firewall
    # Note: This is here to illustrate the fact that the slave is expected to
    # have the same dbs as the master.
    #postgresql::spatialdb { 'gis': }

    system::role { 'role::osm::slave':
        ensure      => 'present',
        description => 'openstreetmaps db slave',
    }

    class {'postgresql::slave':
        # FIXME - top-scope var without namespace ($osm_master), will break in puppet 2.8
        # lint:ignore:variable_scope
        master_server    => $osm_master,
        # lint:endignore
        replication_pass => $passwords::osm::replication_pass,
        includes         => 'tuning.conf',
        root_dir         => $role::osm::common::root_dir,
    }

    class { 'postgresql::ganglia':
        pgstats_user => $passwords::osm::ganglia_user,
        pgstats_pass => $passwords::osm::ganglia_pass,
    }
}
